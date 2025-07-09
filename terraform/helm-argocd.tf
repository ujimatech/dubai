variable "gitops_repo_url" {
  default = "https://github.com/ujimatech/dubai"
}
variable "gitops_repo_branch" {
  default = "multitenant-argocd"
}
variable "tenants" {
  default = ""
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  provider = kubernetes.dubai-kube
}
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

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
  provider = "helm.dubai-kube"
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
      "generators" = [
        {
          "list" = {
            "elements" = [
              for key, tenant in var.tenants : {
                "entityId"  = tenant.entity_id,
                "tenantKey" = key
              }
            ]
          }
        }
      ]
      # This template now creates the PARENT App of Apps
      "template" = {
        "metadata" = {
          # Name of the parent app, e.g., "dubai-8h018eh02e"
          "name" = "${var.project_name}-dddd"
        }
        "spec" = {
          "project" = "default"
          "source" = {
            "repoURL"        = var.gitops_repo_url
            "targetRevision" = var.gitops_repo_branch

            # --- THE KEY CHANGE ---
            # Point to your new 'dubai-bundle' parent chart
            "path"           = "terraform/dubai-bundle"

            "helm" = {
              # This becomes the Helm release name for the parent chart
              "releaseName" = "${var.project_name}-dddd"

              # Pass the tenant identifiers to the parent chart's values.yaml
              "parameters" = [
                {
                  "name"  = "global.entityId"
                  "value" = "dddd"
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
            # The parent app's destination is the tenant namespace
            "namespace" = "${var.project_name}-dddd"
          }
          "syncPolicy" = {
            "automated" = {
              "prune"    = true
              "selfHeal" = true
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.argocd,
  ]
  provider = kubernetes.dubai-kube
}

# # main.tf
#
# # --- Step 1: Fetch the SSH Private Key from AWS Secrets Manager ---
# # This data source securely retrieves the secret value during the terraform apply.
# # The IAM role/user running Terraform needs 'secretsmanager:GetSecretValue' permission.
# data "aws_secretsmanager_secret_version" "argocd_ssh_private_key" {
#   # Use the exact name you gave the secret in AWS Secrets Manager
#   secret_id = "dubai/argocd/git-ssh-private-key"
# }
#
#
# # --- Step 2: Create the Kubernetes Secret for ArgoCD using the fetched value ---
# resource "kubernetes_secret" "private_repo_creds" {
#   metadata {
#     name      = "dubai-gitops-repo"
#     namespace = "argocd"
#     labels = {
#       "argocd.argoproj.io/secret-type" = "repository"
#     }
#   }
#
#   string_data = {
#     "url" = "git@github.com:your-org/your-private-repo.git"
#     "type" = "git"
#
#     # --- THIS IS THE KEY CHANGE ---
#     # Instead of reading from a local file, we use the value retrieved
#     # from the data source above.
#     # Note: If you stored a key/value secret, use jsondecode() to extract the value.
#     # If you stored it as plain text (like the CLI command did), this is all you need.
#     "sshPrivateKey" = data.aws_secretsmanager_secret_version.argocd_ssh_private_key.secret_string
#   }
# }
#
