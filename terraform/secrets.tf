# Ephemeral resource for LLM API Key
ephemeral "random_password" "llm_api_key_value" {
  length  = 48
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Ephemeral resource for PostgreSQL Database Password
ephemeral "random_password" "postgres_password_value" {
  length           = 32
  special          = false
  upper   = true
  lower   = true
  numeric = true
}

# --- LLM API Key Secret ---
resource "aws_secretsmanager_secret" "llm_api_key" {
  name        = "${var.project_name}-llm-api-key"
  description = "LLM API Key for ${var.project_name}"
}

resource "aws_secretsmanager_secret_version" "llm_api_key" {
  secret_id                = aws_secretsmanager_secret.llm_api_key.id
  secret_string_wo         = "sk-${ephemeral.random_password.llm_api_key_value.result}"
  secret_string_wo_version = 1
}

# --- OpenWebUI S3 Access Key ID Secret ---
resource "aws_secretsmanager_secret" "s3_access_key_id" {
  name        = "${var.project_name}-s3-access-key-id"
  description = "OpenWebUI S3 Access Key ID for ${var.project_name}"
}

resource "aws_secretsmanager_secret_version" "s3_access_key_id" {
  secret_id                = aws_secretsmanager_secret.s3_access_key_id.id
  secret_string_wo         = var.s3_access_key_id
  secret_string_wo_version = 1
}

# --- OpenWebUI S3 Secret Access Key Secret ---
resource "aws_secretsmanager_secret" "s3_secret_access_key" {
  name        = "${var.project_name}-s3-secret-access-key"
  description = "OpenWebUI S3 Secret Access Key for ${var.project_name}"
}

resource "aws_secretsmanager_secret_version" "s3_secret_access_key" {
  secret_id                = aws_secretsmanager_secret.s3_secret_access_key.id
  secret_string_wo         = var.s3_secret_access_key
  secret_string_wo_version = 1
}

# --- PostgreSQL DB User Secret ---
resource "aws_secretsmanager_secret" "postgres_db_user" {
  name        = "${var.project_name}-postgres-db-user"
  description = "PostgreSQL DB User for ${var.project_name}"
}

resource "aws_secretsmanager_secret_version" "postgres_db_user" {
  secret_id                = aws_secretsmanager_secret.postgres_db_user.id
  secret_string_wo         = var.postgres_db_user
  secret_string_wo_version = 2
}

# --- PostgreSQL DB Password Secret ---
resource "aws_secretsmanager_secret" "postgres_db_password" {
  name        = "${var.project_name}-postgres-db-password"
  description = "PostgreSQL DB Password for ${var.project_name}"
}

resource "aws_secretsmanager_secret_version" "postgres_db_password" {
  secret_id                = aws_secretsmanager_secret.postgres_db_password.id
  secret_string_wo         = ephemeral.random_password.postgres_password_value.result
  secret_string_wo_version = 2
}