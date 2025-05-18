# outputs.tf

output "autoscaling_group_id" {
  description = "The ID of the AutoScaling Group"
  value       = aws_autoscaling_group.this.id
}

output "autoscaling_group_name" {
  description = "The name of the AutoScaling Group"
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "The ARN of the AutoScaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "instance_tags" {
  description = "The tags applied to instances launched by the ASG"
  value       = local.all_tags
}