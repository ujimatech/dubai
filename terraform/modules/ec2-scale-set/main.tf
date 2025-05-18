# main.tf

locals {
  asg_name    = "${var.fleet_prefix}-${var.environment}"
  min_size    = var.min_size != null ? var.min_size : var.instance_count
  max_size    = var.max_size != null ? var.max_size : var.instance_count
  desired     = var.desired_capacity != null ? var.desired_capacity : var.instance_count

  default_tags = {
    Name        = local.asg_name
    Environment = var.environment
    Terraform   = "true"
    Module      = "ec2-scale-set"
  }

  all_tags = merge(local.default_tags, var.additional_tags)
}

resource "aws_autoscaling_group" "this" {
  name                      = local.asg_name
  min_size                  = local.min_size
  max_size                  = local.max_size
  desired_capacity          = local.desired
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  termination_policies      = var.termination_policies
  target_group_arns         = var.target_group_arns
  wait_for_capacity_timeout = var.wait_for_capacity_timeout

  launch_template {
    id      = var.external_launch_template_id
    version = var.external_launch_template_version
  }

  dynamic "tag" {
    for_each = local.all_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}