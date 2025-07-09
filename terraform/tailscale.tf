module "tailscale" {
  source = "masterpointio/tailscale/aws"
  namespace = "dubai"
  stage     = "prod"
  name      = "tailscale"
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnets
  advertise_routes = [module.vpc.vpc_cidr_block]
  max_size = 1
  ephemeral = true

}

# Define the CloudWatch alarm
resource "aws_cloudwatch_metric_alarm" "ec2_termination_alarm" {
  alarm_name          = "EC2TerminationAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when EC2 instance is terminated"
  actions_enabled     = true

  dimensions = {
    AutoScalingGroupName = module.tailscale.autoscaling_group_id
  }

  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
}

# Define the Auto Scaling policy
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "ScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = module.tailscale.autoscaling_group_id
}


# EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "tailscale_router" {
  subnet_id          = module.vpc.private_subnets[0]  # Deploy in private subnet
  security_group_ids = [aws_security_group.eic_endpoint.id]

  preserve_client_ip = true  # Enable client IP preservation

  tags = {
    Name = "tailscale-router-eice"
  }
}

# Security group for the EC2 Instance Connect Endpoint
resource "aws_security_group" "eic_endpoint" {
  name        = "eic-endpoint-sg"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [module.tailscale.security_group_id]
    description = "Allow outbound SSH to Tailscale router"
  }
}

# Update Tailscale router security group to allow EICE access
resource "aws_security_group_rule" "allow_eice" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eic_endpoint.id
  security_group_id        = module.tailscale.security_group_id
  description             = "Allow SSH from EC2 Instance Connect Endpoint"
}

# IAM role for EC2 instance
resource "aws_iam_role" "tailscale_router" {
  name = "tailscale-router-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Outputs
output "instance_connect_endpoint_id" {
  value       = aws_ec2_instance_connect_endpoint.tailscale_router.id
  description = "EC2 Instance Connect Endpoint ID"
}

