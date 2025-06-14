data "aws_caller_identity" "current" {}
data "aws_secretsmanager_secret_version" "s3_access_key_id" {
  secret_id = aws_secretsmanager_secret.s3_access_key_id.id
}

data "aws_secretsmanager_secret_version" "s3_secret_access_key" {
  secret_id = aws_secretsmanager_secret.s3_secret_access_key.id
}