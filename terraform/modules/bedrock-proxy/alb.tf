# alb.tf

resource "aws_lb" "proxy_alb" {
  name               = "${local.name_prefix}-proxy-alb"
  internal          = var.alb_internal
  load_balancer_type = "application"
  security_groups   = [aws_security_group.proxy_alb.id]
  subnets           = var.subnet_ids

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.proxy_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda.arn
  }
}

resource "aws_lb_target_group" "lambda" {
  name        = "${local.name_prefix}-lambda-tg"
  target_type = "lambda"
  
  health_check {
    enabled             = true
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval           = 30
    matcher            = "200"
  }

}

# Lambda permission to allow ALB invocation
resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowALBInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.proxy_api_handler.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda.arn
}

# Target group attachment
resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = aws_lambda_function.proxy_api_handler.arn
  depends_on       = [aws_lambda_permission.allow_alb]
}