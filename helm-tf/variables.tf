variable "project_name" {
}
variable "infra_remote_state_bucket" {
    description = "S3 bucket where the infrastructure remote state is stored"
    type        = string
}
variable "infra_remote_state_file" {
    description = "Path to the infrastructure remote state file in the S3 bucket"
    type        = string
}
variable "aws_region" {
    description = "AWS region to deploy resources"
    type        = string
}
variable "openrouter_api_key" {
    description = "OpenRouter API key for LLM access"
    default = null
}
variable "entity_id" {
  description = "Entity ID for the deployment"
  type        = string
}
