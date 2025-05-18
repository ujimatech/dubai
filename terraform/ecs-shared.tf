module "ecs_cluster" {
  source       = "terraform-aws-modules/ecs/aws//modules/cluster"
  cluster_name = "cluster-${var.project_name}"

  fargate_capacity_providers = {
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 20
      }
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "ecs_namespace" {
  name        = "dubai.internal"
  vpc         = module.vpc.vpc_id
  description = "Private namespace for ECS service discovery"
}

resource "aws_service_discovery_service" "bedrock" {
  name = "bedrockproxy"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id
    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "openwebui" {
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