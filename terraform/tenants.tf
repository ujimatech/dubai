# main.tf

# --- Step 1: STILL create per-tenant namespaces and secrets ---
# This part of the logic remains, as ArgoCD cannot create secrets from AWS.
resource "kubernetes_namespace" "tenant_apps" {
  for_each = var.tenants
  metadata {
    name = "${var.project_name}-${each.value.entity_id}"
  }
  provider = kubernetes.dubai-kube
}

# resource "kubernetes_secret" "tenant_app_secrets" {
#   for_each = var.tenants
#   metadata {
#     name      = "${var.project_name}-secrets"
#     namespace = kubernetes_namespace.tenant_apps[each.key].metadata[0].name
#   }
#   # ... (data block for secrets remains the same)
# }

# --- Step 2: NEW - Create the ConfigMap that lists all tenants ---
# This ConfigMap acts as the "source of truth" for the ApplicationSet.
resource "kubernetes_config_map" "tenant_list" {
  metadata {
    # This must be in the argocd namespace for the ApplicationSet to find it
    name      = "dubai-tenant-list"
    namespace = "argocd"
    # This label is how the ApplicationSet will discover this ConfigMap
    labels = {
      "argocd.argoproj.io/applicationset" = "dubai-tenants"
    }
  }

  # The data key will contain a YAML-formatted list of our tenants.
  data = {
    "tenants.yaml" = yamlencode([
      # Loop through the tenants variable and create a list of objects
      for key, tenant in var.tenants : {
        # These fields will become the variables available in the ApplicationSet template
        tenantKey      = key
        entityId       = tenant.entity_id
        projectName    = var.project_name
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_branch
      }
    ])
  }

  depends_on = [
    # Ensure namespaces and secrets are created before this ConfigMap.
    kubernetes_namespace.tenant_apps,
    # kubernetes_secret.tenant_app_secrets
  ]
  provider = kubernetes.dubai-kube
}