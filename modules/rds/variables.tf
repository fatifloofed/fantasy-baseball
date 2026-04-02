variable "name_prefix" {
  description = "The prefix for naming resources"
  type        = string
}

variable "db_subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
}

variable "db_sg_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "db_engine_version" {
  description = "The version of the database engine to use"
  type        = string
}

variable "db_instance_class" {
  description = "The instance class to use for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes for the RDS instance"
  type        = number
}

variable "db_max_allocated_storage" {
  description = "The maximum allocated storage in gigabytes for the RDS instance"
  type        = number
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encrypting RDS storage"
  type        = string
}

variable "db_multi_az" {
  description = "Whether to create a Multi-AZ RDS instance"
  type        = bool
  default     = false
}

variable "db_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the RDS credentials"
  type        = string
}

data "aws_secretsmanager_secret_version" "db" {
    secret_id = var.db_secret_arn
}

locals {
    db_creds = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}
