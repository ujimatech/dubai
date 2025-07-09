variable "project_name" {
  description = "Name of the project"
  type        = string
}

#### Secrets #####
variable "tailscale_api_key" {
  description = "Tailscale API key"
  type        = string
  sensitive   = true
}

variable "ts_k8_operator_client_id" {
    description = "Tailscale Kubernetes operator client ID"
    type        = string
    sensitive   = true
}

variable "ts_k8_operator_client_secret" {
    description = "Tailscale Kubernetes operator client secret"
    type        = string
    sensitive   = true
}

variable "s3_access_key_id" {
    description = "S3 access key ID"
    type        = string
    sensitive   = true
  
}
variable "s3_secret_access_key" {
    description = "S3 secret access key"
    type        = string
    sensitive   = true

}

variable "postgres_db_user" {
  description = "Postgres database user"
 type = string
  sensitive = true

}

variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-west-2"
  type        = string
}