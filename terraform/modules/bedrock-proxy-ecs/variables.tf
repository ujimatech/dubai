# -------------------------------
# ECS Cluster Configuration
# -------------------------------
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name for built-in service discovery"
  type        = string
}

variable "ecs_task_port" {
  description = "Port the ECS task listens on"
  type        = number
  default     = 80
}

# -------------------------------
# Networking
# -------------------------------
variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security groups to assign to ECS tasks"
  type        = list(string)
  default = []
}

variable "vpc_id" {
  description = "VPC ID where ECS services are deployed"
  type        = string
}

variable "default_model_id" {
  description = "The default model ID for inference"
  type        = string
}

variable "api_key_secret_arn" {
  description = "The ARN of the API key stored in AWS Secrets Manager"
  type        = string
}

variable "s3_bucket_name" {
}