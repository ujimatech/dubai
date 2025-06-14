#!/bin/bash

set -euo pipefail

# === CONFIGURATION ===
ROLE_TAG="k3s-master"  # Change this if needed
POLL_INTERVAL=15    # seconds
REGION="us-west-2"
ASG_NAME="dubcluster-k3s-prod"
ROLE_TAG="k3s-master"  # Tag to identify the role of the instance


# === FUNCTION TO GET INSTANCE IDS ===
get_instance_ids() {
  aws ec2 describe-instances \
    --region "$REGION" \
    --filters \
      "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
      "Name=tag:Role,Values=$ROLE_TAG" \
      "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text
}

# === MAIN LOOP ===
echo "Waiting for an EC2 instance with Role=$ROLE_TAG in ASG=$ASG_NAME to pass status checks..."

while true; do
  INSTANCE_IDS=$(get_instance_ids)

  if [[ -z "$INSTANCE_IDS" ]]; then
    echo "No running instances found yet. Retrying in $POLL_INTERVAL seconds..."
    sleep "$POLL_INTERVAL"
    continue
  fi

  for INSTANCE_ID in $INSTANCE_IDS; do
    STATUS=$(aws ec2 describe-instance-status \
      --region "$REGION" \
      --instance-ids "$INSTANCE_ID" \
      --query "InstanceStatuses[0].{SystemStatus: SystemStatus.Status, InstanceStatus: InstanceStatus.Status}" \
      --output text)

    SYS_STATUS=$(echo "$STATUS" | awk '{print $1}')
    INST_STATUS=$(echo "$STATUS" | awk '{print $2}')

    if [[ "$SYS_STATUS" == "ok" && "$INST_STATUS" == "ok" ]]; then
      echo "Instance $INSTANCE_ID is healthy (both system and instance status are OK)."
      exit 0
    else
      echo "Instance $INSTANCE_ID not ready yet: System=$SYS_STATUS, Instance=$INST_STATUS"
    fi
  done

  echo "No instance passed health checks yet. Retrying in $POLL_INTERVAL seconds..."
  sleep "$POLL_INTERVAL"
done