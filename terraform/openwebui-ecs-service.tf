module "openwebui-container" {
  source = "terraform-aws-modules/ecs/aws//modules/container-definition"

  name      = "open-webui"
  image     = "ghcr.io/open-webui/open-webui:v0.5.20"
  cpu       = 1024
  memory    = 2048
  essential = true
  readonly_root_filesystem = false

  port_mappings = [
    {
      containerPort = 8080
      protocol      = "tcp"
    }
  ]

  environment = [
    { name = "STORAGE_PROVIDER", value = "s3" },
    { name = "S3_ENDPOINT_URL", value = "https://s3.us-west-2.amazonaws.com" },
    { name = "S3_REGION_NAME", value = "us-west-2" },
    { name = "S3_BUCKET_NAME", value =  aws_s3_bucket.openwebui_storage.bucket },
    { name = "ENV", value = "dev" },
    { name = "OPENAI_API_BASE_URL", value = "http://bedrockproxy.dubai.internal/api/v1" },
    { name = "RAG_OPENAI_API_BASE_URL", value = "http://bedrockproxy.dubai.internal/api/v1" },
    { name = "RAG_EMBEDDING_ENGINE", value = "openai" },
    { name = "RAG_EMBEDDING_MODEL", value = "cohere.embed-english-v3" },
  ]

  secrets = [
    {
      name      = "OPENAI_API_KEY"
      valueFrom = "${aws_secretsmanager_secret.dubai_secrets.arn}:BEDROCKPROXY_API_KEY::"
    },
    {
      name      = "RAG_OPENAI_API_KEY"
      valueFrom = "${aws_secretsmanager_secret.dubai_secrets.arn}:BEDROCKPROXY_API_KEY::"
    },
    {
      name      = "S3_ACCESS_KEY_ID"
      valueFrom = "${aws_secretsmanager_secret.dubai_secrets.arn}:OPENWEBUI_S3_ACCESS_KEY_ID::"
    },
    {
      name      = "S3_SECRET_ACCESS_KEY"
      valueFrom = "${aws_secretsmanager_secret.dubai_secrets.arn}:OPENWEBUI_S3_SECRET_ACCESS_KEY::"
    },
    {
      name      = "DATABASE_URL"
      valueFrom = "${aws_secretsmanager_secret.dubai_secrets.arn}:POSTGRES_DB_URL::"
    },
    {
      name      = "PGVECTOR_DB_URL"
      valueFrom = "${aws_secretsmanager_secret.dubai_secrets.arn}:POSTGRES_VECTOR_DB_URL::"
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = "/ecs/open-webui"
      "awslogs-region"        = "us-west-2"
      "awslogs-create-group"  = "true"
      "awslogs-stream-prefix" = "open-webui"
    }
  }
}

resource "aws_ecs_task_definition" "openwebui_task" {
  family                   = "openwebui-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.openwebui_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.openwebui_ecs_task_role.arn


  container_definitions = jsonencode([
    module.openwebui-container.container_definition
  ])
}

module "openwebui-service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "open-webui"
  cluster_arn = module.ecs_cluster.arn

  task_definition_arn     = aws_ecs_task_definition.openwebui_task.arn
  create_task_definition  = false

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.ecs.id]
  create_security_group = false


  desired_count = 1
  launch_type   = "FARGATE"

  service_registries = {
    registry_arn = aws_service_discovery_service.openwebui.arn
  }

  deployment_circuit_breaker = {
    enable   = true
    rollback = false
  }

}

# IAM Roles
resource "aws_iam_role" "openwebui_ecs_execution_role" {
  name = "${var.project_name}-open-webui-execution-role"

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


# Attach necessary policiesx
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
  name = "${var.project_name}-open-webui-task-role"

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
