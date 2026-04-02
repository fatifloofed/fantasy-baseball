locals {
  ecs_services = ["api", "worker", "scheduled-task"]
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting log data"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string  
}

variable "aws_region" {
  description = "AWS Region"
  type        = string  
}
