terraform {
  backend "s3" {
    bucket = "hrt-statefiles-usw2"
    key    = "dubai-helm.tfstate"
    region = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.83.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 3.0.0-pre2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.27.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      project     = var.project_name
    }
  }
}

provider "awscc" {
  region = var.aws_region
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }

  experiments = {
    manifest = true
  }
}


data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.infra_remote_state_bucket              # Replace with your actual S3 bucket where infra state is stored
    key    = var.infra_remote_state_file # Path to your infra state file
    region = var.aws_region
  }
}