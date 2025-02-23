variable "tailscale_api_key" {
  description = "Tailscale API key"
  type        = string
  sensitive   = true
}

variable "bedrock_api_key_value" {
  description = "Bedrock API key value"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "database_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}