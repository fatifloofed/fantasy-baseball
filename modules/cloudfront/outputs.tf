output "distribution_arn" {
  description = "CloudFront distribution ARN used in the S3 bucket OAC policy condition"
  value       = aws_cloudfront_distribution.web_assets.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.web_assets.domain_name
}

output "distribution_id" {
  value = aws_cloudfront_distribution.web_assets.id
}