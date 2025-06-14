# dubai-storage-helm.tf
resource "helm_release" "dubai_storage" {
  name       = "dubai-storage"
  chart      = "../dubai-controller"
  namespace  = "longhorn-system"
  atomic = true
  replace = true

  set = [
    {
      name  = "global.projectName"
      value = var.project_name
    },
    {
      name  = "global.entityId"
      value = var.entity_id
    }
  ]
}