# resource "aws_secretsmanager_secret" "tailscale_api_key_secret" {
#   name        = "tailscale_api_key"
#   description = "Tailscale API key"
# }
#
# resource "aws_secretsmanager_secret_version" "tailscale_api_key" {
#   secret_id     = aws_secretsmanager_secret.tailscale_api_key_secret.id
#   secret_string = var.tailscale_api_key
# }
#
# data "aws_secretsmanager_secret_version" "tailscale_api_key" {
#   secret_id = aws_secretsmanager_secret.tailscale_api_key_secret.id
# }

module "tailscale" {
  source = "masterpointio/tailscale/aws"

  namespace = "dubai"
  stage     = "prod"
  name      = "tailscale"


  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnets
  advertise_routes = [module.vpc.vpc_cidr_block]


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

