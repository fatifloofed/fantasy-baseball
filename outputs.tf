# Defines the values to export after a successful deployment.

# output "s3_bucket_id" {
#   description = "The ID of the created S3 bucket."
#   # INSTRUCTION: This assumes the module has an output named 'bucket_id'
#   value       = module.app_data_storage.bucket_id
# }
# 
# output "s3_bucket_arn" {
#   description = "The ARN of the created S3 bucket."
#   value       = module.app_data_storage.bucket_arn
# }

output "cloudfront_domain_name" {
  description = "CloudFront distribution URL — point your DNS CNAME here."
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed for cache invalidations."
  value       = module.cloudfront.distribution_id
}