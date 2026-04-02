variable "name_prefix" {
    type = string
}

variable "s3_bucket_regional_domain" {
    type = string
}

variable "s3_log_bucket_domain" {
  description = "Domain name of the ALB/access logs S3 bucket for CloudFront access logs."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = US/EU only (cheapest)."
  type        = string
  default     = "PriceClass_100"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for a custom domain. Must be in us-east-1 (CloudFront requirement). Only required when domain_aliases is set."
  type        = string
  default     = null
}

variable "domain_aliases" {
  description = "List of custom domain aliases for the CloudFront distribution. If empty, the distribution will use the default CloudFront domain."
  type        = list(string)
  default     = []
}