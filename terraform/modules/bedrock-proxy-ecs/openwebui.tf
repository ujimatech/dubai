resource "aws_ecs_task_definition" "open_webui" {
  family                   = "open-webui"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 1024
  memory                  = 2048
  execution_role_arn      = aws_iam_role.openwebui_ecs_execution_role.arn
  task_role_arn          = aws_iam_role.openwebui_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "open-webui"
      image = "ghcr.io/open-webui/open-webui:v0.5.16"

      portMappings = [
        {
          containerPort = 8080
          hostPort     = 8080
          protocol     = "tcp"
        }
      ]

      environment = [
        {
          name  = "STORAGE_PROVIDER"
          value = "s3"
        },
        {
          name  = "S3_ENDPOINT_URL"
          value = "https://s3.us-east-1.amazonaws.com"
        },
        {
          name  = "S3_REGION_NAME"
          value = "us-east-1"
        },
        {
          name  = "S3_BUCKET_NAME"
          value = var.s3_bucket_name
        },
        {
          name  = "ENV"
          value = "dev"
        },
        {
          name  = "OPENAI_API_BASE_URL"
          value = "http://my-ecs-service.dubai.internal/api/v1"
        }
      ]

      secrets = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "${var.api_key_secret_arn}:BEDROCKPROXY_API_KEY::"
        },
        {
          name      = "S3_ACCESS_KEY_ID"
          valueFrom = "${var.api_key_secret_arn}:OPENWEBUI_S3_ACCESS_KEY_ID::"
        },
        {
          name      = "S3_SECRET_ACCESS_KEY"
          valueFrom = "${var.api_key_secret_arn}:OPENWEBUI_S3_SECRET_ACCESS_KEY::"
        },

      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/open-webui"
          "awslogs-region"        = "us-west-2"
          "awslogs-create-group"= "true"
          "awslogs-stream-prefix" = "open-webui"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "open_webui" {
  name            = "open-webui"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.open_webui.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.open_webui.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.open_webui.arn
  }
}

# Security Group
resource "aws_security_group" "open_webui" {
  name        = "open-webui-sg"
  description = "Security group for Open WebUI container"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["sg-070b7c10ca4a657f9"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Service Discovery
resource "aws_service_discovery_service" "open_webui" {
  name = "open-webui"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}


# IAM Roles
resource "aws_iam_role" "openwebui_ecs_execution_role" {
  name = "${var.ecs_service_name}-open-webui-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "openwebui_ecs_execution_role_policy" {
  role       = aws_iam_role.openwebui_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "openwebui_ecs_task_execution_attach" {
  role       = aws_iam_role.openwebui_ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}


resource "aws_iam_role" "openwebui_ecs_task_role" {
  name = "${var.ecs_service_name}-open-webui-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "openwebui_ecs_task_role_attach" {
  role       = aws_iam_role.openwebui_ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "open_webui" {
  name              = "/ecs/open-webui"
  retention_in_days = 7
}