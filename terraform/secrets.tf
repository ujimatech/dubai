resource "aws_secretsmanager_secret" "dubai_secrets" {
  name        = "${var.project_name}-secrets"
  description = "Secrets for the ${var.project_name} project"
}

resource "aws_secretsmanager_secret_version" "dubai_secrets" {
   secret_id     = aws_secretsmanager_secret.dubai_secrets.id
   secret_string = jsonencode(
    {
      "BEDROCKPROXY_API_KEY": var.bedrock_api_key_value,
      "OPENWEBUI_S3_ACCESS_KEY_ID": var.s3_access_key_id,
      "OPENWEBUI_S3_SECRET_ACCESS_KEY": var.s3_secret_access_key,
      "POSTGRES_DB_URL": "postgresql://${var.postgres_db_user}:${var.postgres_db_password}@dubai-cluster.cluster-cxe2ucjcjpel.us-west-2.rds.amazonaws.com:5432",
      "POSTGRES_DB_USER": var.postgres_db_user,
      "POSTGRES_DB_PASSWORD": var.postgres_db_password
    }
   )
}