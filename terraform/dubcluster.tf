#-------------------------------------
# Supporting Resources
# ---------------------------------------

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_s3_bucket" "k3s_config_bucket" {
  bucket = "${var.project_name}-k3s-config"
}

# Configure default encryption for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "k3s_config_bucket" {
  bucket = aws_s3_bucket.k3s_config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------
# IAM Configuration
# ---------------------------------------

resource "aws_iam_role" "k3s_role" {
  name = "dubcluster-k3s-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Policy to allow EC2 instances to discover each other (needed for nodes to join the cluster)
resource "aws_iam_policy" "ec2_discovery_policy" {
  name        = "dubcluster-k3s-discovery-policy"
  description = "Allows K3s nodes to discover each other"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:CreateTags",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource"
        ]
        Resource = [aws_secretsmanager_secret.k3s_token.id]
      }
    ]
  })
}

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "ec2_discovery" {
  role       = aws_iam_role.k3s_role.name
  policy_arn = aws_iam_policy.ec2_discovery_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "k3s_profile" {
  name = "dubcluster-k3s-profile"
  role = aws_iam_role.k3s_role.name
}

# ---------------------------------------
# Security Group Configuration
# ---------------------------------------

resource "aws_security_group" "k3s_sg" {
  name        = "dubcluster-k3s-sg"
  description = "Security group for K3s cluster nodes"
  vpc_id = module.vpc.vpc_id

  # Allow all internal traffic within the security group
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    description = "Allow all traffic between cluster nodes"
  }

  # K3s API Server
  ingress {
    from_port   = 0
    to_port     = 0

    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s API Server"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dubcluster-k3s-sg"
  }
}

# ---------------------------------------
# K3s Cluster Secret
# ---------------------------------------

# Create a secret for K3s token (for node joining)
resource "aws_secretsmanager_secret" "k3s_token" {
  name        = "dubcluster-k3s-token"
  description = "K3s cluster token for node joining"
}

resource "random_uuid" "k3s_token" {}

resource "aws_secretsmanager_secret_version" "k3s_token" {
  secret_id     = aws_secretsmanager_secret.k3s_token.id
  secret_string = random_uuid.k3s_token.result
}

# ---------------------------------------
# Launch Template Configuration
# ---------------------------------------

resource "aws_launch_template" "k3s" {
  name          = "dubcluster-k3s-template"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "m7g.large" # Good balance for K3s nodes


  iam_instance_profile {
    name = aws_iam_instance_profile.k3s_profile.name
  }

  instance_market_options {
    market_type = "spot"

    spot_options {
      spot_instance_type = "one-time"
      instance_interruption_behavior = "terminate"
    }
  }

  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 50 # Enough for K3s and basic workloads
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "dubcluster-k3s-node"
    }
  }

  # Optionally enable detailed monitoring for production clusters
  monitoring {
    enabled = false
  }
}

# ---------------------------------------
# EC2 Auto Scaling Group
# ---------------------------------------

module "k3s_cluster" {
  source = "./modules/ec2-scale-set"

  fleet_prefix                  = "dubcluster-k3s"
  environment                   = "prod"
  instance_count                = 1 # Start with 3 nodes (1 master, 2 workers)
  external_launch_template_id   = aws_launch_template.k3s.id
  external_launch_template_version = "$Latest"
  subnet_ids                    = module.vpc.private_subnets

  # min_size                      = 0
  # max_size                      = 0

  health_check_type             = "EC2"
  health_check_grace_period     = 300

  additional_tags = {
    Project     = "DubCluster"
    Component   = "K3s"
    ClusterName = "dubcluster"
  }


   termination_policies          = ["OldestLaunchTemplate"]
}

module "k3s_provisioner" {
  source = "./modules/ssm-script-runner"

  document_name = "dubcluster-k3s-provisioner"
  bash_script   = "scripts/k3s-bootstrap.sh"

  # Define parameters that will be used in the script
  set_document_parameters = {
    CLUSTERNAME = {
      type        = "String"
      description = "Name of the K3s cluster"
      default     = var.project_name
    },
    K3SVERSION = {
      type        = "String"
      description = "Version of K3s to install"
      default     = "v1.33.0+k3s1"
    },
    ASGNAME = {
      type        = "String"
      description = "Auto Scaling Group name"
    },
    TOKENSECRETNAME = {
      type        = "String"
      description = "AWS Secrets Manager secret name for cluster token"
    },
    K3SCONFIGBUCKET = {
      type        = "String"
      description = "k3s config bucket name"
      default     = aws_s3_bucket.k3s_config_bucket.id
    },
    REGION = {
      type        = "String"
      description = "AWS region"
      default     = var.aws_region
    }
  }

  # Parameter values to pass to the script
  parameters = {
    CLUSTERNAME      = "dubcluster"
    K3SVERSION       = "v1.33.0+k3s1"
    ASGNAME          = module.k3s_cluster.autoscaling_group_name
    TOKENSECRETNAME = aws_secretsmanager_secret.k3s_token.name
    REGION           = var.aws_region
    CLUSTERNAME     = var.project_name
  }

  # Enable automatic association to run on all instances
  enable_association = true

  # Target instances by Name tag
  target_tags        = {
    "aws:autoscaling:groupName" = module.k3s_cluster.autoscaling_group_name
  }

  # Set compliance reporting
  compliance_severity = "HIGH"

  # Run on 100% of instances, to ensure all nodes are configured
  max_concurrency     = "100%"
  max_errors          = "25%"
}

resource null_resource "k3s_OK_trigger" {
  provisioner "local-exec" {
      interpreter = ["/bin/bash", "-c"]
      command = "./scripts/wait-for-k3s-master.sh"
      environment = {
        REGION = var.aws_region
        ASG_NAME   = module.k3s_cluster.autoscaling_group_name
      }
  }
  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "load-k3s-config" {
    provisioner "local-exec" {
        interpreter = ["/bin/bash", "-c"]
        command = "./scripts/load-k3s-config.sh"
        environment = {
          S3_BUCKET_NAME = aws_s3_bucket.k3s_config_bucket.id
        }
    }
    triggers = {
            always_run = timestamp()
    }

    depends_on = [
        null_resource.k3s_OK_trigger,
        module.k3s_provisioner
    ]
}


# ---------------------------------------
# Outputs
# ---------------------------------------

output "k3s_cluster_asg_name" {
  description = "Name of the K3s cluster Auto Scaling Group"
  value       = "dubcluster-k3s-prod"
}

# output "k3s_cluster_size" {
#   description = "Current size of the K3s cluster"
#   value       = module.k3s_cluster.instance_count
# }

output "k3s_master_discovery_command" {
  description = "AWS CLI command to discover the current K3s master node"
  value       = "aws ec2 describe-instances --filters \"Name=tag:Role,Values=k3s-master\" \"Name=instance-state-name,Values=running\" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text"
}