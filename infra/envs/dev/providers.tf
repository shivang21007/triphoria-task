terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {}  # configure via: terraform init -backend-config=backend.hcl
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
