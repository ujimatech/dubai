# variables.tf

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "lambda_subnet_ids" {
  description = "List of subnet IDs for the lambda"
  type        = list(string)
}

variable "alb_internal" {
    description = "Whether the ALB is internal"
    type        = bool
    default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Additional variables for variables.tf

variable "lambda_image_uri" {
  description = "URI of the Lambda container image"
  type        = string
}

variable "debug_mode" {
  description = "Enable debug mode for Lambda function"
  type        = string
  default     = "false"
}

variable "default_embedding_model" {
  description = "Default embedding model to use"
  type        = string
  default     = "cohere.embed-multilingual-v3"
}

variable "default_model" {
  description = "Default Bedrock model to use"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "enable_cross_region_inference" {
  description = "Enable cross-region inference"
  type        = string
  default     = "true"
}

variable "ephemeral_storage_size" {
  description = "Size of ephemeral storage for Lambda function in MB"
  type        = number
  default     = 512
}

variable "bedrock_api_key_secret_arn" {
    description = "ARN of the Bedrock API key secret"
    type        = string
}

# # variables.tf - Add these new variables
# variable "use_private_subnets" {
#   description = "Whether to place the ALB in private subnets"
#   type        = bool
#   default     = false
# }
#
# variable "private_subnet_ids" {
#   description = "List of private subnet IDs for the ALB when using private subnets"
#   type        = list(string)
#   default     = []
# }
#
# variable "public_subnet_ids" {
#   description = "List of public subnet IDs for the ALB when using public subnets"
#   type        = list(string)
#   default     = []
# }

# Additional variables for variables.tf

variable "create_api_key_param" {
  description = "Whether to create the API key parameter in SSM"
  type        = bool
  default     = false
}

variable "api_key_param_name" {
  description = "Name of the SSM parameter to store the API key"
  type        = string
  default     = null
}

variable "api_key_value" {
  description = "Value of the API key to store in SSM"
  type        = string
  default     = null
  sensitive   = true
}

variable "create_log_level_param" {
  description = "Whether to create the log level parameter in SSM"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Log level for the application"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR"
  }
}