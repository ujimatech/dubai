#!/bin/bash
# k3s-bootstrap.sh - Bootstraps a K3s node as either master or worker

set -e

# Access SSM parameters
CLUSTERNAME="{{ CLUSTERNAME }}"
K3SVERSION="{{ K3SVERSION }}"
ASGNAME="{{ ASGNAME }}"
TOKENSECRETNAME="{{ TOKENSECRETNAME }}"

# Configure logging
exec > >(tee /var/log/k3s-bootstrap.log) 2>&1
echo "Starting K3s bootstrap at $(date)"
echo "Cluster name: $CLUSTERNAME"
echo "K3s version: $K3SVERSION"
echo "ASG name: $ASGNAME"
echo "Token secret name: $TOKENSECRETNAME"

# Ensure AWS CLI and other needed tools are installed
apt-get update && apt-get install -y \
  curl \
  jq \
  awscli \
  nfs-common \
  open-iscsi

# Get information about this instance
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/hostname)

# Tag the instance with its hostname
aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=hostname,Value=$HOSTNAME" --region "$REGION"

# Function to get K3s token from Secrets Manager
get_k3s_token() {
  aws secretsmanager get-secret-value \
    --secret-id "$TOKENSECRETNAME" \
    --region "$REGION" \
    --query SecretString \
    --output text
}

# Function to check if this instance should become a master
should_be_master() {
  # Check if a master already exists by looking for the k3s-master tag in the ASG
  master_count=$(aws ec2 describe-instances \
    --filters "Name=tag:Role,Values=k3s-master" \
             "Name=tag:aws:autoscaling:groupName,Values=$ASGNAME" \
             "Name=instance-state-name,Values=running,pending" \
    --region "$REGION" \
    --query 'length(Reservations[].Instances[])' \
    --output text)

  # If no masters, this instance should be master
  if [ "$master_count" -eq "0" ]; then
    return 0
  else
    return 1
  fi
}

# Function to get the master node's IP
get_master_ip() {
  aws ec2 describe-instances \
    --filters "Name=tag:Role,Values=k3s-master" \
             "Name=tag:aws:autoscaling:groupName,Values=$ASGNAME" \
             "Name=instance-state-name,Values=running" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text
}

# Function to check if K3s is already installed
is_k3s_installed() {
  if [ -f "/usr/local/bin/k3s" ]; then
    return 0
  else
    return 1
  fi
}

# Function to check if this node is already part of a cluster
is_in_cluster() {
  if [ -f "/etc/rancher/k3s/k3s.yaml" ] || systemctl is-active --quiet k3s || systemctl is-active --quiet k3s-agent; then
    return 0
  else
    return 1
  fi
}

# Function to install K3s as master
install_k3s_master() {
  echo "Installing K3s as master node..."

  # Get or create token
  K3S_TOKEN=$(get_k3s_token)

  # Install K3s as server (master)
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3SVERSION" \
    K3S_TOKEN="$K3S_TOKEN" \
    sh -s - server \
    --cluster-init \
    --node-ip "$PRIVATE_IP" \
    --tls-san "$PRIVATE_IP" \
    --disable traefik \
    --disable servicelb \
    --write-kubeconfig-mode 644

  # Tag this instance as master
  aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=Role,Value=k3s-master" --region "$REGION"

  # Create secrets to help worker nodes join
  mkdir -p /var/lib/rancher/k3s/server
  echo "Creating k3s token in Secrets Manager..."

  # Update the secret with the actual token
  K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
  aws secretsmanager update-secret \
    --secret-id "$TOKENSECRETNAME" \
    --secret-string "$K3S_TOKEN" \
    --region "$REGION"

  # Create a secret for the master's IP
  aws secretsmanager create-secret \
    --name "${TOKENSECRETNAME}-master-ip" \
    --description "K3s master node IP address" \
    --secret-string "$PRIVATE_IP" \
    --region "$REGION" \
    --tags "Key=ClusterName,Value=$CLUSTERNAME" \
    || aws secretsmanager update-secret \
    --secret-id "${TOKENSECRETNAME}-master-ip" \
    --secret-string "$PRIVATE_IP" \
    --region "$REGION"

  echo "K3s master installation complete!"

  # Wait for the node to become ready
  sleep 10
  KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl wait --for=condition=Ready node/$HOSTNAME --timeout=60s

  # Apply node label for master role
  KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl label node $HOSTNAME node-role.kubernetes.io/master=true --overwrite

  # Install Helm (useful for further deployments)
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

# Function to install K3s as worker
install_k3s_worker() {
  echo "Installing K3s as worker node..."

  # Get the master IP and token
  MASTER_IP=$(get_master_ip)
  K3S_TOKEN=$(get_k3s_token)

  if [ -z "$MASTER_IP" ] || [ "$MASTER_IP" == "None" ]; then
    echo "Error: Could not determine master node IP. Exiting."
    return 1
  fi

  if [ -z "$K3S_TOKEN" ] || [ "$K3S_TOKEN" == "None" ]; then
    echo "Error: Could not retrieve K3s token. Exiting."
    return 1
  fi

  echo "Joining cluster with master at $MASTER_IP"

  # Install K3s as agent (worker)
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3SVERSION" \
    K3S_URL="https://$MASTER_IP:6443" \
    K3S_TOKEN="$K3S_TOKEN" \
    sh -s - agent \
    --node-ip "$PRIVATE_IP"

  # Tag this instance as worker
  aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=Role,Value=k3s-worker" --region "$REGION"

  echo "K3s worker installation complete!"
}

# Main execution flow
if is_in_cluster; then
  echo "Node is already part of a K3s cluster. Checking for updates..."

  # Check if role tag exists, if not, determine and set role
  CURRENT_ROLE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].Tags[?Key==`Role`].Value' \
    --output text)

  if [ -z "$CURRENT_ROLE" ] || [ "$CURRENT_ROLE" == "None" ]; then
    echo "Role tag missing. Determining role..."

    # Check if this is a master or worker by looking for k3s-server process
    if systemctl is-active --quiet k3s; then
      aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=Role,Value=k3s-master" --region "$REGION"
      echo "This node has been tagged as k3s-master"
    else
      aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=Role,Value=k3s-worker" --region "$REGION"
      echo "This node has been tagged as k3s-worker"
    fi
  fi

  echo "Node is already configured as part of the K3s cluster."
else
  echo "K3s is not installed or not running. Proceeding with installation..."

  # Determine if this should be master or worker
  if should_be_master; then
    echo "This node will be the master"
    install_k3s_master
  else
    echo "This node will be a worker"
    install_k3s_worker
  fi
fi

# Verify the installation
if systemctl is-active --quiet k3s || systemctl is-active --quiet k3s-agent; then
  echo "K3s is running successfully!"

  # Update hostnames in /etc/hosts to improve node communication
  echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

  # Perform post-installation tasks based on role
  ROLE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].Tags[?Key==`Role`].Value' \
    --output text)

  if [ "$ROLE" == "k3s-master" ]; then
    echo "Running master-specific post-installation tasks..."

    # Create a config map with cluster info for worker nodes
    KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl create configmap cluster-info \
      --from-literal=master-ip="$PRIVATE_IP" \
      --from-literal=cluster-name="$CLUSTERNAME" \
      -n kube-system --dry-run=client -o yaml | KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl apply -f -

    # Install metrics-server if needed
    if ! KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get deployment metrics-server -n kube-system &>/dev/null; then
      echo "Installing metrics-server..."
      KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    fi
  fi
else
  echo "ERROR: K3s installation failed or service is not running"
  exit 1
fi

echo "K3s bootstrap completed successfully at $(date)"
exit 0