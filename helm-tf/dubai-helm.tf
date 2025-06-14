resource "kubernetes_namespace" "entity-namespace" {
  metadata {
    name = local.entity_namespace

  }
}

# 7. Deploy OpenWebUI Helm Chart
resource "helm_release" "dubai-interface" {
  name       = "${var.project_name}-openwebui" # Ensure var.project_name in helm-tf/variables.tf is set if needed, or adjust naming
  chart      = "../dubai"                # Assuming this path is correct relative to the helm-tf directory
  namespace  = kubernetes_namespace.entity-namespace.metadata[0].name
  atomic = true
  replace = true

  values = [
    file("../dubai/values.yaml"), # Ensure this path is correct
  ]

  set = [
    {
      name  = "global.projectName"
      value = var.project_name
    },
    {
      name  = "global.entityId"
      value = var.entity_id
    },
    {
      name  = "openwebui.persistence.storageClassName"
      value = "${var.project_name}-${var.entity_id}"
    },
    {
      name  = "litellm.persistence.storageClassName"
      value = "${var.project_name}-${var.entity_id}"
    },
    {
      name  = "openwebui.secrets.OPENAI_API_KEY"
      value = local.llm_api_key_value
    },
    {
      name  = "openwebui.secrets.RAG_OPENAI_API_KEY"
      value = local.llm_api_key_value
    },
    {
      name  = "openwebui.secrets.S3_ACCESS_KEY_ID"
      value = local.s3_access_key_id_value
    },
    {
      name  = "openwebui.secrets.S3_SECRET_ACCESS_KEY"
      value = local.s3_secret_access_key_value
    },
    {
      name  = "openwebui.secrets.DATABASE_URL"
      value = "${local.pgvector_db_url_base}/${var.project_name}"
    },
    {
      name  = "openwebui.secrets.PGVECTOR_DB_URL"
      value = "${local.pgvector_db_url_base}/${var.project_name}-vector"
      # Example: postgresql://user:pass@host:port/dubai-vector
    },
    {
      name  = "litellm.secrets.master_key"
      value = local.llm_api_key_value
    },
    {
      name  = "litellm.openrouter.openrouter_api_key"
      value = local.openrouter_api_key_value
    }
  ]

  depends_on = [
    helm_release.dubai_storage,
    kubernetes_namespace.entity-namespace,
    aws_secretsmanager_secret_version.openrouter_api_key
  ]
}