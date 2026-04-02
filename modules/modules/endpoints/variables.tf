variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created."
  type        = string
}

variable "name_prefix" {
  description = "The prefix for naming resources, typically in the format 'application-environment'."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the resources will be created."
  type        = string
}

variable "route_table_ids" {
  description = "S3 route table ID for the endpoint"
  type        = list(string)
}

variable "endpoint_sg_id" {
  description = "Security group ID for interface endpoints"
  type        = string
}

variable "app_subnet_ids" {
  description = "Subnet IDs for interface endpoints"
  type        = list(string)
}

locals {
    interface_endpoints = {
        "ecr-api" = "com.amazonaws.${var.aws_region}.ecr.api"
        "ecr-dkr" = "com.amazonaws.${var.aws_region}.ecr.dkr"
        "secretsmanager" = "com.amazonaws.${var.aws_region}.secretsmanager"
        "logs" = "com.amazonaws.${var.aws_region}.logs"
    }
}