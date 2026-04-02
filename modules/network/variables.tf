variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "A map of CIDR blocks for the public subnets."
  type        = map(object({
    cidr_block = string
    az = string
    tier = string
  }))
}

variable "private_subnets" {
  description = "A map of CIDR blocks for the private subnets."
  type        = map(object({
    cidr_block = string
    az = string
    tier = string
  }))
}


variable "tags" {
  description = "Default tags applied to all resources"
  type = map(string)
}