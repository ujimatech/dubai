# # 2. Retrieve K3s kubeconfig from S3
# data "aws_s3_object" "k3s_kubeconfig" {
#   bucket = data.terraform_remote_state.infra.outputs.k3s_config_bucket_name
#   key    = "k3s_config.yaml"
#
# }

# 4. Retrieve application secrets from Secrets Manager
data "aws_secretsmanager_secret_version" "llm_api_key" {
  secret_id = data.terraform_remote_state.infra.outputs.llm_api_key_secret_name
}

data "aws_secretsmanager_secret_version" "s3_access_key_id" {
  secret_id = data.terraform_remote_state.infra.outputs.s3_access_key_id_secret_name
}

data "aws_secretsmanager_secret_version" "s3_secret_access_key" {
  secret_id = data.terraform_remote_state.infra.outputs.s3_secret_access_key_secret_name
}

data "aws_secretsmanager_secret_version" "postgres_db_user" {
  secret_id = data.terraform_remote_state.infra.outputs.postgres_db_user_secret_name
}

data "aws_secretsmanager_secret_version" "postgres_db_password" {
  secret_id = data.terraform_remote_state.infra.outputs.postgres_db_password_secret_name
}

data "aws_secretsmanager_secret_version" "openrouter_api_key" {
  secret_id = aws_secretsmanager_secret.openrouter_api_key[0].id
  depends_on = [
    aws_secretsmanager_secret_version.openrouter_api_key
  ]
}
