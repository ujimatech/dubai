# output "longhorn_namespace_name" {
#   description = "The name of the Longhorn namespace"
#   value       = kubernetes_namespace.longhorn_namespace.metadata[0].name
# }
#
# output "longhorn_manager_secret_name" {
#   description = "The name of the Longhorn manager secret"
#   value       = kubernetes_secret.longhorn_manager.metadata[0].name
# }
#
# output "longhorn_release_name" {
#   description = "The name of the Longhorn Helm release"
#   value       = helm_release.longhorn.name
# }
#
# output "longhorn_release_version" {
#   description = "The version of the Longhorn Helm release"
#   value       = helm_release.longhorn.version
# }
#
# output "longhorn_release_namespace" {
#   description = "The namespace of the Longhorn Helm release"
#   value       = helm_release.longhorn.namespace
# }
# -------------------------------------------
# Outputs for AWS Infrastructure
# -------------------------------------------
output "k3s_config_bucket_name" {
  value = aws_s3_bucket.k3s_config_bucket.id
}

# -------------------------------------------
# RDS Outputs
# -------------------------------------------

output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_rds_cluster.aurora_cluster.id
}

output "rds_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_rds_cluster.aurora_cluster.endpoint
}

output "rds_instance_reader_endpoint" {
  value = aws_rds_cluster.aurora_cluster.reader_endpoint
}

# -------------------------------------------
# Secrets Outputs
# -------------------------------------------
output "llm_api_key_secret_arn" {
  description = "The ARN of the LLM API Key secret"
  value       = aws_secretsmanager_secret.llm_api_key.arn
}

output "llm_api_key_secret_name" {
  description = "The name of the LLM API Key secret"
  value       = aws_secretsmanager_secret.llm_api_key.name
}

output "s3_access_key_id_secret_arn" {
  description = "The ARN of the S3 Access Key ID secret"
  value       = aws_secretsmanager_secret.s3_access_key_id.arn
}

output "s3_access_key_id_secret_name" {
  description = "The name of the S3 Access Key ID secret"
  value       = aws_secretsmanager_secret.s3_access_key_id.name
}

output "s3_secret_access_key_secret_arn" {
  description = "The ARN of the S3 Secret Access Key secret"
  value       = aws_secretsmanager_secret.s3_secret_access_key.arn
}

output "s3_secret_access_key_secret_name" {
  description = "The name of the S3 Secret Access Key secret"
  value       = aws_secretsmanager_secret.s3_secret_access_key.name
}

output "postgres_db_user_secret_arn" {
  description = "The ARN of the PostgreSQL DB User secret"
  value       = aws_secretsmanager_secret.postgres_db_user.arn
}

output "postgres_db_user_secret_name" {
  description = "The name of the PostgreSQL DB User secret"
  value       = aws_secretsmanager_secret.postgres_db_user.name
}

output "postgres_db_password_secret_arn" {
  description = "The ARN of the PostgreSQL DB Password secret"
  value       = aws_secretsmanager_secret.postgres_db_password.arn
}

output "postgres_db_password_secret_name" {
  description = "The name of the PostgreSQL DB Password secret"
  value       = aws_secretsmanager_secret.postgres_db_password.name
}