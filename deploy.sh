cd terraform && \
AWS_PROFILE=management S3_BUCKET_NAME=dubai-k3s-config scripts/load-k3s-config.sh && \
AWS_PROFILE=management terraform apply -var-file=vars/temp.tfvars --auto-approve && \
cd ../helm-tf && \
AWS_PROFILE=management terraform apply -var-file=vars/dev.tfvars --auto-approve && \
helm upgrade --install code-server ~/workspace/code-server/ci/helm-chart -f ~/workspace/code-server/coder/values.yaml -n dubai-8h018eh02e
