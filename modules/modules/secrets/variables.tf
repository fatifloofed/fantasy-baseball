variable "kms_key_arn" {
    description = "The ARN of the KMS key to use for encrypting secrets"
    type        = string
}

variable "name_prefix" {
    description = "The prefix for naming resources"
    type        = string
}

