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
