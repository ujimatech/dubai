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

resource "kubernetes_manifest" "root_app_of_apps" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "root-dubai-applications"
      "namespace" = "argocd"
      "finalizers" = [
        # This ensures that if you destroy this root app, ArgoCD will first delete
        # all the resources it created, preventing orphaned resources.
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    "spec" = {
      "project" = "default"
      "source" = {
        # Point to the Git repo and the path where you stored the ApplicationSet YAML
        "repoURL"        = var.gitops_repo_url
        "targetRevision" = var.gitops_repo_branch
        "path"           = "terraform/argocd-config" # The directory you created in Step 1
      }
      "destination" = {
        # The destination for the resources found in the 'path'.
        # The ApplicationSet object itself needs to be created in the argocd namespace.
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "argocd"
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
    }
  }

  depends_on = [
    helm_release.argocd,
  ]
  provider = kubernetes.dubai-kube
}