# --- Create a namespace for EACH tenant ---
resource "kubernetes_namespace" "tenant_apps" {
  for_each = var.tenants

  metadata {
    # e.g., "dubai-8h018eh02e"
    name = "${var.project_name}-${each.value.entity_id}"
  }
  provider = kubernetes.dubai-kube

}

# # --- Fetch secrets and create a Kubernetes secret for EACH tenant ---
# # (This assumes the secrets are the same for all tenants for simplicity)
# data "aws_secretsmanager_secret_version" "llm_api_key" {
#   secret_id = data.terraform_remote_state.infra.outputs.llm_api_key_secret_name
# }
# # ... add other data sources for secrets
#
# resource "kubernetes_secret" "tenant_app_secrets" {
#   for_each = var.tenants
#
#   metadata {
#     name = "${var.project_name}-secrets"
#     # Create the secret in the correct tenant namespace
#     namespace = kubernetes_namespace.tenant_apps[each.key].metadata[0].name
#   }
#
#   data = {
#     OPENAI_API_KEY     = base64encode(data.aws_secretsmanager_secret_version.llm_api_key.secret_string)
#     # ... add other secrets here
#   }
#
#   type = "Opaque"
# }