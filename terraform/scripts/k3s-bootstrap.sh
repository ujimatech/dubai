#!/bin/bash
# Optimized k3s-bootstrap.sh

set -euo pipefail

# Logging setup
LOG_FILE="/var/log/k3s-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Constants
TEMP_CONFIG="/tmp/k3s_config.yaml"

# SSM Parameters
CLUSTERNAME="{{ CLUSTERNAME }}"
K3SVERSION="{{ K3SVERSION }}"
ASGNAME="{{ ASGNAME }}"
TOKENSECRETNAME="{{ TOKENSECRETNAME }}"
K3SCONFIGBUCKET="{{ K3SCONFIGBUCKET }}"

# Metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/hostname)

# Ensure tools are present
apt-get update && apt-get install -y curl jq awscli nfs-common open-iscsi
# Install Helm (useful for further deployments)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Tag instance with hostname
echo "Tagging instance..."
aws ec2 create-tags --resources "$INSTANCE_ID" --tags Key=hostname,Value=$HOSTNAME --region "$REGION"

get_k3s_token() {
  aws secretsmanager get-secret-value \
    --secret-id "$TOKENSECRETNAME" \
    --region "$REGION" \
    --query SecretString \
    --output text
}

should_be_master() {
  master_count=$(aws ec2 describe-instances \
    --filters "Name=tag:Role,Values=k3s-master" \
             "Name=tag:aws:autoscaling:groupName,Values=$ASGNAME" \
             "Name=instance-state-name,Values=running,pending" \
    --region "$REGION" \
    --query 'length(Reservations[].Instances[])' \
    --output text)
  [ "$master_count" -eq 0 ]
}

get_master_ip() {
  aws ec2 describe-instances \
    --filters "Name=tag:Role,Values=k3s-master" \
             "Name=tag:aws:autoscaling:groupName,Values=$ASGNAME" \
             "Name=instance-state-name,Values=running" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text
}

is_k3s_installed() {
  [[ -f "/usr/local/bin/k3s" ]]
}

is_in_cluster() {
  [[ -f "/etc/rancher/k3s/k3s.yaml" ]] || systemctl is-active --quiet k3s || systemctl is-active --quiet k3s-agent
}

install_k3s_master() {
  echo "Installing K3s master..."

  K3S_TOKEN=$(get_k3s_token)
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3SVERSION" \
    K3S_TOKEN="$K3S_TOKEN" \
    sh -s - server \
    --cluster-init \
    --node-ip "$PRIVATE_IP" \
    --write-kubeconfig-mode 644 \

  aws ec2 create-tags --resources "$INSTANCE_ID" --tags Key=Role,Value=k3s-master --region "$REGION"

  k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.2/cert-manager.yaml

  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  kubectl wait --for=condition=Ready node/$HOSTNAME --timeout=60s
  kubectl label node "$HOSTNAME" node-role.kubernetes.io/master=true --overwrite

  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  cp "$KUBECONFIG" "$TEMP_CONFIG"
  sed -i "s|server: https://[^:]*:6443|server: https://${PRIVATE_IP}:6443|" "$TEMP_CONFIG"

  aws s3 cp "$TEMP_CONFIG" "s3://${K3SCONFIGBUCKET}/k3s_config.yaml"
  rm -f "$TEMP_CONFIG"
}

install_k3s_worker() {
  echo "Installing K3s worker..."
  MASTER_IP=$(get_master_ip)
  K3S_TOKEN=$(get_k3s_token)

  [[ -n "$MASTER_IP" && "$MASTER_IP" != "None" ]] || { echo "Invalid master IP" >&2; return 1; }
  [[ -n "$K3S_TOKEN" && "$K3S_TOKEN" != "None" ]] || { echo "Invalid K3s token" >&2; return 1; }

  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3SVERSION" \
    K3S_URL="https://$MASTER_IP:6443" \
    K3S_TOKEN="$K3S_TOKEN" \
    sh -s - agent \
    --node-ip "$PRIVATE_IP"

  aws ec2 create-tags --resources "$INSTANCE_ID" --tags Key=Role,Value=k3s-worker --region "$REGION"
}

# Main logic
if is_in_cluster; then
  echo "Already in cluster. Verifying role..."
  CURRENT_ROLE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].Tags[?Key==`Role`].Value' \
    --output text)

  if [[ -z "$CURRENT_ROLE" || "$CURRENT_ROLE" == "None" ]]; then
    if systemctl is-active --quiet k3s; then
      aws ec2 create-tags --resources "$INSTANCE_ID" --tags Key=Role,Value=k3s-master --region "$REGION"
    else
      aws ec2 create-tags --resources "$INSTANCE_ID" --tags Key=Role,Value=k3s-worker --region "$REGION"
    fi
  fi
else
  echo "Node not in cluster. Installing..."
  if should_be_master; then
    install_k3s_master
  else
    install_k3s_worker
  fi
fi

if systemctl is-active --quiet k3s || systemctl is-active --quiet k3s-agent; then
  echo "K3s is running. Applying post-install tasks."
  echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

  ROLE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].Tags[?Key==`Role`].Value' \
    --output text)

  if [[ "$ROLE" == "k3s-master" ]]; then
    kubectl create configmap cluster-info \
      --from-literal=master-ip="$PRIVATE_IP" \
      --from-literal=cluster-name="$CLUSTERNAME" \
      -n kube-system --dry-run=client -o yaml | kubectl apply -f -

    if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
      kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    fi
    KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    cp "$KUBECONFIG" "$TEMP_CONFIG"
    sed -i "s|server: https://[^:]*:6443|server: https://${PRIVATE_IP}:6443|" "$TEMP_CONFIG"

    aws s3 cp "$TEMP_CONFIG" "s3://${K3SCONFIGBUCKET}/k3s_config.yaml"
    rm -f "$TEMP_CONFIG"

  fi
else
  echo "ERROR: K3s failed to start." >&2
  exit 1
fi

echo "Bootstrap complete at $(date)"
