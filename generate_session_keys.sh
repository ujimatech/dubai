#!/bin/bash

# Check if role ARN is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <role-arn>"
    exit 1
fi

ROLE_ARN="$1"

# Assume the role and get temporary credentials
credentials=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "OpenWebUISession" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)

# Check if credentials were obtained successfully
if [ $? -ne 0 ]; then
    echo "Failed to assume role"
    exit 1
fi

# Parse credentials into separate variables
ACCESS_KEY=$(echo "$credentials" | cut -f1)
SECRET_KEY=$(echo "$credentials" | cut -f2)
SESSION_TOKEN=$(echo "$credentials" | cut -f3)

# Create environment variables file
{
    echo "STORAGE_PROVIDER=s3"
    echo "S3_ACCESS_KEY_ID=$ACCESS_KEY"
    echo "S3_SECRET_ACCESS_KEY=$SECRET_KEY"
    echo "AWS_SESSION_TOKEN=$SESSION_TOKEN"
    echo "S3_ENDPOINT_URL=https://s3.us-east-1.amazonaws.com"
    echo "S3_REGION_NAME=us-east-1"
    echo "S3_BUCKET_NAME=my-awesome-bucket-name"
    echo "ENV=dev"
} > temp.txt
