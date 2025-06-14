resource "kubernetes_namespace" "longhorn_namespace" {
  depends_on = [
    null_resource.load-k3s-config
  ]

  metadata {
    name = "longhorn-system"
  }
  provider = kubernetes.dubai-kube
}

resource "kubernetes_secret" "longhorn_manager" {
  depends_on = [
    null_resource.load-k3s-config
  ]
  metadata {
    name      = "${var.project_name}-longhorn-manager"
    namespace = kubernetes_namespace.longhorn_namespace.id
  }

  data = {
    accessKey = data.aws_secretsmanager_secret_version.s3_access_key_id.secret_string
    secretKey = data.aws_secretsmanager_secret_version.s3_secret_access_key.secret_string
  }

  type = "Opaque"
  provider = kubernetes.dubai-kube
}

resource "helm_release" "longhorn" {
  depends_on = [
    null_resource.load-k3s-config,
  ]
  provider = helm.dubai-kube

  name       = "longhorn"
  chart      = "longhorn"
  namespace  = "longhorn-system"
  repository = "https://charts.longhorn.io"
  version    = "1.9.0"
  atomic = true
  replace = true

  set = [
    {
      name = "defaultBackupStore.backupTarget"
      value = "s3://hrt-codeserver-backup@us-west-2/"
    },
    {
      name = "defaultBackupStore.backupTargetCredentialSecret"
        value = kubernetes_secret.longhorn_manager.metadata[0].name
    }
  ]
}