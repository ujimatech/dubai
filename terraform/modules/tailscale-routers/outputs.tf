# outputs.tf
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.tailscale_router.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.tailscale_router.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.tailscale_router.id
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.tailscale_router.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.tailscale_router.arn
}