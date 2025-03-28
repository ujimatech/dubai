module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "DubAI-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway  = true
  enable_vpn_gateway = false

}

# module "fck-nat" {
#   source = "RaJiska/fck-nat/aws"
#
#   name                 = "my-fck-nat"
#   vpc_id               = "vpc-abc1234"
#   subnet_id            = "subnet-abc1234"
#   # ha_mode              = true                 # Enables high-availability mode
#   # eip_allocation_ids   = ["eipalloc-abc1234"] # Allocation ID of an existing EIP
#   # use_cloudwatch_agent = true                 # Enables Cloudwatch agent and have metrics reported
#
#   update_route_tables = true
#   route_tables_ids = {
#     "your-rtb-name-A" = "rtb-abc1234Foo"
#     "your-rtb-name-B" = "rtb-abc1234Bar"
#   }
# }

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
