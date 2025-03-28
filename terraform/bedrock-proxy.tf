# # resource "aws_secretsmanager_secret" "bedrockproxy_api_key_secret" {
# #   name        = "BedrockProxyApiKey"
# #   description = "Tailscale API key"
# # }
# #
# # resource "aws_secretsmanager_secret_version" "bedrock_proxy_api_key" {
# #    secret_id     = aws_secretsmanager_secret.bedrockproxy_api_key_secret.id
# #    secret_string = jsonencode(
# #     {
# #       "api_key": var.bedrock_api_key_value
# #     }
# #    )
# # }
# #
# # data "aws_secretsmanager_secret_version" "bedrock_proxy_api_key" {
# #   secret_id = jsondecode(aws_secretsmanager_secret.bedrockproxy_api_key_secret.id)["api_key"]
# # }
#
# module "bedrock-proxy" {
#   source = "./modules/bedrock-proxy-ecs"
#
#   api_key_secret_arn = aws_secretsmanager_secret_version.dubai_secrets.arn
#   default_model_id   = ""
#   private_subnet_ids = module.vpc.private_subnets
#   security_group_ids = [aws_security_group.ecs.id]
#   vpc_id             = module.vpc.vpc_id
#   s3_bucket_name = aws_s3_bucket.openwebui_storage.id
#   ecs_cluster_name = "cluster-${var.project_name}"
#   ecs_service_name = "service-${var.project_name}"
# }
#
resource "aws_security_group" "ecs" {
  name        = "ecs-security-group"
  description = "Security group for ECS service communication"
  vpc_id      = module.vpc.vpc_id

  # Allow ECS tasks to communicate with each other
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow internal communication between ECS tasks"
  }

  ingress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = [module.tailscale.security_group_id]
    description     = "Allow ECS tasks to communicate with Tailscale router"
  }

  # Allow outbound traffic to anywhere (for dependencies like databases)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

