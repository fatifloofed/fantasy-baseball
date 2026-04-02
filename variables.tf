# All variables required by the module are declared here. 
# Environment-specific variables should generally not have a `default` value.

variable "application" {
  description = "The application name to be used for tagging and naming."
  type        = string
}

variable "environment" {
  description = "The deployment environment name (e.g., dev, uat, prod) to be used for tagging and naming."
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of 'dev', 'uat', or 'prod'."
  }
}

variable "aws_account_id" {
  description = "The AWS Account ID to deploy the resources."
  type        = string  
}

variable "assume_role_arn" {
  description = "The IAM Role ARN to be used for the provide assume_role."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy the resources."
  type        = string
}

# NETWORKING

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "A map of CIDR blocks for the public subnets."
  type        = map(object({
    cidr_block = string
    az = string
  }))
}

variable "private_app_subnets" {
  description = "A map of CIDR blocks for the private subnets."
  type        = map(object({
    cidr_block = string
    az = string
  }))
}

variable "private_db_subnets" {
  description = "Map of private DB-tier subnets. Key = logical name."
  type = map(object({
    cidr_block = string
    az         = string
  }))
}

# Web Tier

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB. Must be in the same region."
  type        = string
}

# App Tier

variable "ecs_task_cpu" {
  description = "Default vCPU units for ECS tasks (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "Default memory (MiB) for ECS tasks."
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "Desired task count for the API service."
  type        = number
  default     = 2
}

variable "worker_desired_count" {
  description = "Desired task count for the Worker service."
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port the API container listens on."
  type        = number
  default     = 8080
}

variable "capacity_providers" { 
    type = list(string) 
}

# DB Tier

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.2"
}

variable "db_allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Upper limit for autoscaling storage in GiB."
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS."
  type        = bool
  default     = false
}


#################        TAGS VARIABLES      ######################
variable "tags_project_id" {
  type        = string
  description = "Tags Project ID"
  default     = ""
}

variable "tags_BU" {
  type        = string
  description = "Tags Business Unit"
  default     = ""
}

variable "tags_IT" {
  type        = string
  description = "Tags IT Unit"
  default     = ""
}

variable "tags_desc" {
  type        = string
  description = "Tags Description"
  default     = ""
}

variable "tags_cost_center" {
  type        = string
  description = "Tags Cost Center"
  default     = ""
}


