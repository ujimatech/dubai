# module "bedrock-proxy-container" {
#   source = "terraform-aws-modules/ecs/aws//modules/container-definition"
#
#   name      = "proxy-api"
#   image     = "366590864501.dkr.ecr.us-west-2.amazonaws.com/bedrock-proxy-api-ecs:latest"
#   cpu       = 1024
#   memory    = 2048
#   essential = true
#   readonly_root_filesystem = false
#
#   port_mappings = [
#     {
#       containerPort = 80
#       protocol      = "tcp"
#     }
#   ]
#
#   environment = [
#     { name = "DEBUG", value = "false" },
#     # { name = "DEFAULT_MODEL", value = var.default_model_id },
#     { name = "DEFAULT_EMBEDDING_MODEL", value = "cohere.embed-multilingual-v3" },
#     { name = "ENABLE_CROSS_REGION_INFERENCE", value = "true" }
#   ]
#
#   secrets = [
#     {
#       name      = "API_KEY"
#       valueFrom = "${aws_secretsmanager_secret.dubai_secrets.arn}:BEDROCKPROXY_API_KEY::"
#     }
#   ]
# }
#
# resource "aws_ecs_task_definition" "bedrock_proxy_task" {
#   family                   = "bedrock-task"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "1024"
#   memory                   = "2048"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
#
#   container_definitions = jsonencode([
#     module.bedrock-proxy-container.container_definition
#   ])
# }
#
# module "bedrock-proxy-service" {
#   source = "terraform-aws-modules/ecs/aws//modules/service"
#
#   name        = "bedrock-proxy-api"
#   cluster_arn = module.ecs_cluster.arn
#
#   task_definition_arn = aws_ecs_task_definition.bedrock_proxy_task.arn
#   create_task_definition = false
#   desired_count = 0
#
#   subnet_ids         = module.vpc.private_subnets
#   security_group_ids = [aws_security_group.ecs.id]
#   create_security_group = false
#   capacity_provider_strategy = [
#   {
#     capacity_provider = "FARGATE_SPOT"
#     weight            = 100
#   }
# ]
#
#   service_registries = {
#     registry_arn = aws_service_discovery_service.bedrock.arn
#   }
#
#   deployment_circuit_breaker = {
#     enable   = true
#     rollback = false
#   }
#
#
# }