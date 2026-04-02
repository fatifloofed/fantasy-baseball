# All variables required by the module are declared here. 
# Environment-specific variables should generally not have a `default` value.

variable "application" {
  description = "The application name to be used for tagging and naming."
  type        = string
}

variable "environment" {
  description = "The deployment environment name (e.g., dev, uat, prod) to be used for tagging and naming."
  type        = string
}

variable "aws_account_id" {
  description = "The AWS Account ID to deploy the resources."
  type        = string  
}

variable "assume_role_arn" {
  description = "The IAM Role ARN to be used for the provide assume_role."
  type        = string
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

variable "tags_tier" {
  type        = string
  description = "Tags tier"
  default     = ""
}

variable "tags_automation" {
  type        = bool
  description = "Tags automation"
  default     = false
}

variable "tags_sched" {
  type        = bool
  description = "Tags sched"
  default     = false
}

#################        LOCAL VARIABLES      ######################
locals {
  name_prefix = "${var.application}-${var.environment}"
}