# -------------------------------
# AWS Service Discovery for ECS
# -------------------------------
resource "aws_service_discovery_private_dns_namespace" "ecs_namespace" {
  name        = "dubai.internal"
  vpc         = var.vpc_id
  description = "Private namespace for ECS service discovery"
}

resource "aws_service_discovery_service" "ecs_service_discovery" {
  name = "my-ecs-service"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id

    dns_records {
      ttl  = 86400
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# -------------------------------
# ECS Cluster
# -------------------------------
resource "aws_ecs_cluster" "my_cluster" {
  name = var.ecs_cluster_name
}

# -------------------------------
# Enable Fargate Spot in the Cluster
# -------------------------------
resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {
  cluster_name = aws_ecs_cluster.my_cluster.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}

resource "aws_ecs_service" "my_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

service_registries {
  registry_arn = aws_service_discovery_service.ecs_service_discovery.arn
}
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }
}

# -------------------------------
# ECS Task Definition for Fargate
# -------------------------------
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "proxy-api"
      image     = "366590864501.dkr.ecr.us-west-2.amazonaws.com/bedrock-proxy-api-ecs:latest"
      cpu       = 512
      memory    = 1024
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DEBUG", value = "false" },
        { name = "DEFAULT_MODEL", value = var.default_model_id },
        { name = "DEFAULT_EMBEDDING_MODEL", value = "cohere.embed-multilingual-v3" },
        { name = "ENABLE_CROSS_REGION_INFERENCE", value = "true" }
      ]

      secrets = [
        {
          name      = "API_KEY"
          valueFrom = "${var.api_key_secret_arn}:api_key::"
        }
      ]
    }
  ])
}
