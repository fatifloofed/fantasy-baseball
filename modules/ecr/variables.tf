locals {
  repos = ["api", "worker", "scheduled-task"]
}

variable "name_prefix" {
  description = "The prefix for naming resources"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encrypting ECR repositories"
  type        = string
}

data "aws_caller_identity" "current" {}

