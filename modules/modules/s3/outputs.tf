output "web_assets_bucket_regional_domain" {
  description = "Regional domain name for the web assets bucket"
  value       = aws_s3_bucket.web_assets.bucket_regional_domain_name
}

output "web_assets_bucket_id" {
  value = aws_s3_bucket.web_assets.id
}

output "web_assets_bucket_arn" {
  value = aws_s3_bucket.web_assets.arn
}

output "alb_logs_bucket_id" {
  value = aws_s3_bucket.alb.id
}


output "alb_logs_bucket_domain" {
  description = "Domain name of the ALB logs bucket, reused for CloudFront access logging."
  value       = aws_s3_bucket.alb.bucket_domain_name
}