terraform {
  required_version = ">=1.11.0"
  backend "s3" {
    bucket = "hrt-statefiles-usw2"
    key    = "dubai-infra.tfstate"
    region = "us-west-2"
  }

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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
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

provider "kubernetes" {
  alias = "dubai-kube"

  config_path = "~/.kube/config"
}

provider "helm" {
  alias = "dubai-kube"
  kubernetes = {
    config_path = "~/.kube/config"
  }

}
