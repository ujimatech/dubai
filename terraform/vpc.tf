module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "DubAI-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

}


####
# Its possible to get internal DNS resolution working with Tailscale by using Route 53 Resolver.
# However, this shit cost $182 per month
####
# resource "aws_route53_resolver_endpoint" "inbound" {
#   name      = "dubai-resolver-endpoint"
#   direction = "INBOUND"
#
#   security_group_ids = [aws_security_group.resolver.id]
#
#   ip_address {
#     subnet_id = module.vpc.public_subnets[0]
#   }
#
#   ip_address {
#     subnet_id = module.vpc.private_subnets[0]
#   }
# }
#
# resource "aws_security_group" "resolver" {
#   name        = "resolver-endpoint-sg"
#   description = "Security group for Route 53 Resolver endpoint"
#   vpc_id      = module.vpc.vpc_id
#
#   ingress {
#     from_port       = 53
#     to_port         = 53
#     protocol        = "tcp"
#     security_groups = [module.tailscale.security_group_id]
#   }
#
#   ingress {
#     from_port       = 53
#     to_port         = 53
#     protocol        = "udp"
#     security_groups = [module.tailscale.security_group_id]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
