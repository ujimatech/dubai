# module "s3_bucket" {
#   source = "terraform-aws-modules/s3-bucket/aws"
#
#   bucket        = "dubai-knowledgebase"
#   force_destroy = true
# }
#
# resource "awscc_bedrock_knowledge_base" "dubai_kb" {
#   name        = "dubai-knowledge-base"
#   description = "Dubai Knowledge Base using Aurora PostgreSQL"
#   role_arn    = aws_iam_role.bedrock_kb_role.arn
#
#   knowledge_base_configuration = {
#     type = "VECTOR"
#     vector_knowledge_base_configuration = {
#       embedding_model_arn = "arn:aws:bedrock:us-west-2::foundation-model/amazon.titan-embed-text-v2:0"
#       embedding_model_configuration = {
#         bedrock_embedding_model_configuration = {
#           dimensions          = 1024 # Standard dimension for most Bedrock embedding models
#           embedding_data_type = "FLOAT32"
#         }
#       }
#     }
#   }
#   storage_configuration = {
#     type = "RDS"
#     rds_configuration = {
#       database_name          = aws_rds_cluster.aurora_cluster.database_name
#       endpoint               = aws_rds_cluster.aurora_cluster.endpoint
#       port                   = 5432
#       auth_type              = "SECRETS_MANAGER"
#       credentials_secret_arn = aws_secretsmanager_secret.db_credentials.arn
#       resource_arn = aws_rds_cluster.aurora_cluster.arn
#
#       field_mapping = {
#         metadata_field    = "metadata"
#         primary_key_field = "id"
#         text_field        = "content"
#         vector_field      = "embedding"
#       }
#
#       table_name = "knowledge_embeddings"
#     }
#   }
# }
#
# # IAM Role for Bedrock Knowledge Base
# resource "aws_iam_role" "bedrock_kb_role" {
#   name = "bedrock-kb-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "bedrock.amazonaws.com"
#         }
#       }
#     ]
#   })
# }
#
# # IAM Policy for Bedrock to access Aurora and Secrets Manager
# resource "aws_iam_role_policy" "bedrock_kb_policy" {
#   name = "bedrock-kb-policy"
#   role = aws_iam_role.bedrock_kb_role.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "rds-db:connect",
#           "rds-data:ExecuteStatement",
#           "rds:Describe*",
#           "rds:List*",
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = [
#           aws_rds_cluster.aurora_cluster.arn,
#           aws_secretsmanager_secret.db_credentials.arn
#         ]
#       }
#     ]
#   })
# }
#
# # Secrets Manager secret for database credentials
# resource "aws_secretsmanager_secret" "db_credentials" {
#   name = "dubai-kb-db-credentials"
# }
#
# resource "aws_secretsmanager_secret_version" "db_credentials" {
#   secret_id = aws_secretsmanager_secret.db_credentials.id
#   secret_string = jsonencode({
#     username = aws_rds_cluster.aurora_cluster.master_username
#     password = var.database_password
#     engine   = "postgres"
#     port     = 5432
#     host     = aws_rds_cluster.aurora_cluster.endpoint
#     dbname   = aws_rds_cluster.aurora_cluster.database_name
#   })
# }