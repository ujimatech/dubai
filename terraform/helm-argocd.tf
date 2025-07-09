resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.1.2"

  # -- Enable the ApplicationSet Controller --
  set = [
    {
      name  = "applicationset.enabled"
      value = "true"
    }
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

resource "kubernetes_manifest" "dubai_applicationset" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "ApplicationSet"
    "metadata" = {
      "name"      = "${var.project_name}-appset"
      "namespace" = "argocd"
    }
    "spec" = {
      # Use the "List" generator to provide a static list of tenants
      "generators" = [
        {
          "list" = {
            # Terraform will construct this list of elements dynamically
            "elements" = [
              for key, tenant in var.tenants : {
                # These key-value pairs become the template variables (e.g., {{entityId}})
                "entityId" = tenant.entity_id
                "tenantKey" = key # e.g., "tenant-alpha"
              }
            ]
          }
        }
      ]
      # This is the template for each ArgoCD Application that will be created
      "template" = {
        "metadata" = {
          # e.g., "dubai-8h018eh02e"
          "name" = "${var.project_name}-{{entityId}}"
        }
        "spec" = {
          "project" = "default"
          "source" = {
            "repoURL"        = var.gitops_repo_url
            "targetRevision" = var.gitops_repo_branch
            "path"           = var.gitops_app_chart_path
            "helm" = {
              "releaseName" = "${var.project_name}-interface"
              # Pass tenant-specific values to the Helm chart
              "parameters" = [
                {
                  "name"  = "global.entityId"
                  "value" = "{{entityId}}"
                },
                {
                  "name"  = "global.projectName"
                  "value" = var.project_name
                }
              ]
            }
          }
          "destination" = {
            "server"    = "https://kubernetes.default.svc"
            # Deploy into the tenant's dedicated namespace
            "namespace" = "${var.project_name}-{{entityId}}"
          }
          "syncPolicy" = {
            "automated" = {
              "prune"    = true
              "selfHeal" = true
            }
            "syncOptions" = [
              "CreateNamespace=false" # Terraform manages the namespace
            ]
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.tenant_app_secrets
  ]
}