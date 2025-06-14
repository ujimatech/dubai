# Parse kubeconfig and secrets, and construct dynamic values
locals {
  # Kubeconfig details
  k3s_kubeconfig_parsed = yamldecode(file("~/.kube/config")) # Corrected reference
  k3s_cluster_host      = lookup(local.k3s_kubeconfig_parsed.clusters[0].cluster, "server")
  k3s_cluster_ca_cert   = lookup(local.k3s_kubeconfig_parsed.clusters[0].cluster, "certificate-authority-data")
  # k3s_token             = data.aws_secretsmanager_secret_version.k3s_token_version.secret_string
  entity_namespace        = "${var.project_name}-${var.entity_id}"

  # Retrieved application secrets
  llm_api_key_value          = data.aws_secretsmanager_secret_version.llm_api_key.secret_string
  s3_access_key_id_value     = data.aws_secretsmanager_secret_version.s3_access_key_id.secret_string
  s3_secret_access_key_value = data.aws_secretsmanager_secret_version.s3_secret_access_key.secret_string
  postgres_db_user_value     = data.aws_secretsmanager_secret_version.postgres_db_user.secret_string
  postgres_db_password_value = data.aws_secretsmanager_secret_version.postgres_db_password.secret_string
  openrouter_api_key_value   = data.aws_secretsmanager_secret_version.openrouter_api_key.secret_string
  pgvector_db_url_base = "postgresql://${local.postgres_db_user_value}:${local.postgres_db_password_value}@${data.terraform_remote_state.infra.outputs.rds_instance_endpoint}"
}