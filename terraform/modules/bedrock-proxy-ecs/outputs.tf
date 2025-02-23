# -------------------------------
# ECS Outputs
# -------------------------------
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.my_cluster.name
}

output "ecs_service_name" {
  description = "ECS service name for built-in service discovery"
  value       = aws_ecs_service.my_service.name
}

# output "ecs_task_dns" {
#   description = "DNS name for ECS service discovery"
#   value       = aws_ecs_service.my_service.service_registries.
# }
