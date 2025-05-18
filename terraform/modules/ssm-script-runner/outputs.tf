# outputs.tf

output "document_name" {
  description = "The name of the SSM document created"
  value       = aws_ssm_document.script_document.name
}

output "document_arn" {
  description = "The ARN of the SSM document created"
  value       = aws_ssm_document.script_document.arn
}

output "association_id" {
  description = "The ID of the SSM association"
  value       = var.enable_association ? aws_ssm_association.script_association[0].association_id : null
}

output "association_name" {
  description = "The name of the SSM association"
  value       = var.enable_association ? aws_ssm_association.script_association[0].association_name : null
}