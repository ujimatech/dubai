# security_groups.tf
resource "aws_security_group" "proxy_alb" {
  name_prefix = "${var.project_name}-proxy-alb-"
  description = "Security Group for Bedrock Proxy ALB"
  vpc_id      = var.vpc_id

  egress {
    cidr_blocks = ["255.255.255.255/32"]
    description = "Disallow all traffic"
    from_port   = "252"
    protocol    = "icmp"
    self        = "false"
    to_port     = "86"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow from anyone on port 80"
    from_port   = "80"
    protocol    = "tcp"
    self        = "false"
    to_port     = "80"
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.proxy_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}