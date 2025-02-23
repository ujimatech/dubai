# asg.tf
resource "aws_autoscaling_group" "tailscale_router" {
  name                = "${local.name_prefix}-tailscale-router"
  desired_capacity    = var.asg_desired_capacity
  max_size           = var.asg_max_size
  min_size           = var.asg_min_size
  target_group_arns  = var.target_group_arns
  vpc_zone_identifier = var.use_private_subnets ? var.private_subnet_ids : var.public_subnet_ids

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.tailscale_router.id
        version           = "$Latest"
      }
    }
  }

  tag {
    key                 = "Name"
    value              = "${local.name_prefix}-tailscale-router"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }
}

# launch_template.tf
resource "aws_launch_template" "tailscale_router" {
  name_prefix   = "${local.name_prefix}-tailscale-router"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.tailscale_router.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.tailscale_router.name
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    tailscale_auth_key     = var.tailscale_auth_key
    advertised_routes      = var.advertised_routes
    enable_ip_forwarding   = true
    tailscale_hostname     = "${local.name_prefix}-router"
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-tailscale-router"
      }
    )
  }
}

# security_group.tf
resource "aws_security_group" "tailscale_router" {
  name_prefix = "${local.name_prefix}-tailscale-router"
  vpc_id      = var.vpc_id
  description = "Security group for Tailscale subnet router"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
    description = "SSH access (temporary)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-tailscale-router-sg"
    }
  )
}

# iam.tf
resource "aws_iam_role" "tailscale_router" {
  name_prefix = "${local.name_prefix}-tailscale-router"

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

  tags = local.common_tags
}

resource "aws_iam_instance_profile" "tailscale_router" {
  name_prefix = "${local.name_prefix}-tailscale-router"
  role        = aws_iam_role.tailscale_router.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.tailscale_router.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}