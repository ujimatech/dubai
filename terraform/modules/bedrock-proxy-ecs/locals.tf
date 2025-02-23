locals {
  # ECS Service Discovery Settings
  ecs_cluster_name   = var.ecs_cluster_name
  ecs_service_name   = var.ecs_service_name
  ecs_task_port      = var.ecs_task_port

  # Networking
  private_subnet_ids = var.private_subnet_ids
  security_group_ids = var.security_group_ids
  vpc_id             = var.vpc_id
}
