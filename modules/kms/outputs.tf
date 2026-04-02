output "secrets_key_arn" {
  description = "ARN of the application KMS key."
  value       = aws_kms_key.secrets_kms_key.arn
}

output "services_key_arn" {
  description = "ARN of the application KMS key."
  value       = aws_kms_key.services_kms_key.arn
}

output "secrets_key_id" {
  description = "Key ID of the application KMS key."
  value       = aws_kms_key.secrets_kms_key.key_id
}

output "services_key_id" {
  description = "Key ID of the application KMS key."
  value       = aws_kms_key.services_kms_key.key_id
}

output "cloudwatch_key_arn" {
  description = "ARN of the CloudWatch Logs KMS key."
  value       = aws_kms_key.cloudwatch.arn
}
