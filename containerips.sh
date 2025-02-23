#!/bin/bash

# Set AWS Region and ECS Service Details
AWS_REGION="us-west-2"
AWS_PROFILE="management"
CLUSTER_NAME="my-ecs-cluster"
SERVICE_NAME="my-ecs-service"

# Get list of running task ARNs
TASK_ARNS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --query "taskArns[]" --output text --region $AWS_REGION --profile $AWS_PROFILE)

if [ -z "$TASK_ARNS" ]; then
    echo "❌ No running tasks found for service $SERVICE_NAME in cluster $CLUSTER_NAME"
    exit 1
fi

# Get task details and extract container IP addresses
IP_LIST=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARNS \
  --query "tasks[*].attachments[0].details[?name=='privateIPv4Address'].value | [*]" \
  --output text --region $AWS_REGION --profile $AWS_PROFILE)

# Check if IPs were found
if [ -z "$IP_LIST" ]; then
    echo "❌ No container IPs found"
    exit 1
fi

# Format the output as "http://<ip>/api/v1;http://<ip>/api/v1"
FORMATTED_URLS=$(echo "$IP_LIST" | tr '\t' '\n' | awk '{print "http://"$1"/api/v1"}' | paste -sd ";" -)

echo "$FORMATTED_URLS"
