# Generate start for Terraform that will used AWS provider

terraform {
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.83.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.17.2"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      project     = "dubai"
      environment = "dev"
      terraform   = "true"
    }
  }
}

provider "awscc" {
  region = "us-west-2"

}

provider "tailscale" {
  api_key = var.tailscale_api_key
}

# module "tailscale-router" {
#   source = "./modules/tailscale-routers"
#
#   advertised_routes  = ""
#   ami_id             = ""
#   tailscale_auth_key = ""
# }
# http://Bedroc-Proxy-UNcI1BpF0yeA-1099258264.us-west-2.elb.amazonaws.com/api/v1

