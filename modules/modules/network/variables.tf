# --- Private app tier: one RT per AZ pointing to the AZ-local NAT GW ---
# Build a map: AZ => nat_gateway key (relies on public subnets having one per AZ)
locals {
  # Map: az => public subnet key
  public_subnet_key_by_az = { for k, v in var.public_subnets : v.az => k }

  # Map: app subnet key => nat gateway key (same AZ)
  app_subnet_nat_key = {
    for k, v in var.private_app_subnets :
    k => local.public_subnet_key_by_az[v.az]
  }
}

variable "name_prefix" {
  description = "The prefix for naming resources, typically in the format 'application-environment'."
  type        = string
}

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
  description = "A map of CIDR blocks for the private app tier subnets."
  type        = map(object({
    cidr_block = string
    az = string
  }))
}

variable "private_db_subnets" {
  description = "A map of CIDR blocks for the private db tier subnets."
  type        = map(object({
    cidr_block = string
    az = string
  }))
}

