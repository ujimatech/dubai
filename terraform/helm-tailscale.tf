resource "kubernetes_namespace" "tailscale" {
  metadata {
    name = "tailscale"
  }
  provider = kubernetes.dubai-kube
}

resource "helm_release" "tailscale_operator" {
  name       = "tailscale-operator"
  chart      = "tailscale/tailscale-operator"
  namespace  = kubernetes_namespace.tailscale.metadata[0].name
  atomic     = true

  set = [
    {
      name  = "oauth.clientId"
      value = var.ts_k8_operator_client_id
    },
    {
      name  = "oauth.clientSecret"
      value = var.ts_k8_operator_client_secret
    }
  ]

  provider = helm.dubai-kube
}