# --- Providers Block (Standard) ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 6.0"
    }
  }
  required_version = "~> 1.14"
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.assume_role_arn
  }
  default_tags {
    tags = {
      ProjectName  = var.application
      ProjectID    = var.tags_project_id
      Description  = var.tags_desc
      CostCenter   = var.tags_cost_center
      Environment  = upper(var.environment)
      BU           = var.tags_BU
      IT           = var.tags_IT
    }
  }
}