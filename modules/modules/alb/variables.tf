variable "name_prefix" {
    type = string
}

variable "alb_sg_id" {
    description = "Security group IDs"
    type = list(string)
}

variable "public_subnets" {
    description = "Public web subnets"
    type = list(string)
}


variable "certificate_arn" { 
    type = string 
}


variable "s3_log_bucket" { 
    type = string 
}

variable "container_port" {
    type = number
}

variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created."
  type        = string
}
