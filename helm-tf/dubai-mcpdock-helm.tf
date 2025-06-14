# mcp-dock-helm.tf
resource "helm_release" "mcp_dock" {
  name      = "mcp-dock"
  chart     = "../mcp-dock"
  namespace = "${var.project_name}-${var.entity_id}"
  depends_on = [helm_release.dubai-interface]
  atomic = true

  set = [
    {
      name  = "global.projectName"
      value = "dubai"
    },
    {
      name  = "global.entityId"
      value = var.entity_id
    },
    {
      name  = "persistence.storageClassName"
      value = "dubai-${var.entity_id}"
    }
  ]
}