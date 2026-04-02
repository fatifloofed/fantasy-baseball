variable "name_prefix" {
  description = "The prefix for naming resources"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encrypting S3 buckets"
  type        = string
}

data "aws_iam_policy_document" "web_tls" {
  statement {
    sid     = "DenyNonTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.web_assets.arn,
      "${aws_s3_bucket.web_assets.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_elb_service_account" "main" {}

variable "aws_account_id" {
  description = "The AWS Account ID to allow ALB log delivery"
  type        = string  
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution to read web assets"
  type        = string  
}

data "aws_iam_policy_document" "web_assets_cf" {
  # Allow CloudFront to read objects via OAC
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web_assets.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.cloudfront_distribution_arn]
    }
  }


  # statement {
  #   sid     = "DenyNonTLS"
  #   effect  = "Deny"
  #   actions = ["s3:*"]
  #   resources = [
  #     aws_s3_bucket.web_assets.arn,
  #     "${aws_s3_bucket.web_assets.arn}/*",
  #   ]
  #   principals {
  #     type        = "*"
  #     identifiers = ["*"]
  #   }
  #   condition {
  #     test     = "Bool"
  #     variable = "aws:SecureTransport"
  #     values   = ["false"]
  #   }
  # }
}