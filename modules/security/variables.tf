variable "name_prefix" {
  description = "The prefix for naming resources, typically in the format 'application-environment'."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created."
  type        = string
}

variable "container_port" {
  description = "The port on which the API container listens"
  type        = number
}