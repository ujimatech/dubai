# outputs.tf

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.proxy_alb.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.proxy_alb.arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.proxy_alb.zone_id
}

output "lambda_function_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.proxy_api_handler.function_name
}

output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = aws_lambda_function.proxy_api_handler.arn
}

output "security_group_id" {
  description = "ID of the security group attached to the ALB"
  value       = aws_security_group.proxy_alb.id
}

output "target_group_arn" {
  description = "ARN of the Lambda target group"
  value       = aws_lb_target_group.lambda.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.proxy_alb.dns_name}"
}