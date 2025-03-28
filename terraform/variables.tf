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

variable "bedrock_api_key_value" {
  description = "Bedrock API key value"
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
variable "postgres_db_url" {


}
variable "postgres_db_user" {
  description = "Postgres database user"
 type = string
  sensitive = true

}
variable "postgres_db_password" {
 description = "Postgres database password"
    type = string
    sensitive = true
}