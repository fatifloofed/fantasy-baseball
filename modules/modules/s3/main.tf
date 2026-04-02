resource "aws_s3_bucket" "web_assets" {
    bucket = "${var.name_prefix}-web-assets"

    tags = {
        Name = "${var.name_prefix}-web-assets"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "web_assets_encryption" {
    bucket = aws_s3_bucket.web_assets.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "aws:kms"
            kms_master_key_id = var.kms_key_arn
        }
        bucket_key_enabled = true
    }
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
    bucket = aws_s3_bucket.web_assets.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "web" {
    bucket = aws_s3_bucket.web_assets.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}



# resource "aws_s3_bucket_policy" "web" {
#   bucket = aws_s3_bucket.web_assets.id
#   policy = data.aws_iam_policy_document.web_tls.json

#   depends_on = [aws_s3_bucket_public_access_block.web]
# }

resource "aws_s3_bucket" "alb" {
    bucket = "${var.name_prefix}-alb-logs"

    tags = {
        Name = "${var.name_prefix}-alb-logs"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb" {
  bucket = aws_s3_bucket.alb.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket                  = aws_s3_bucket.alb.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb" {
  bucket = aws_s3_bucket.alb.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "alb" {
  bucket = aws_s3_bucket.alb.id
  policy = data.aws_iam_policy_document.alb.json

  depends_on = [aws_s3_bucket_public_access_block.alb_logs]
}

data "aws_iam_policy_document" "alb" {
  statement {
    sid    = "AllowALBLogDelivery"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb.arn}/alb/AWSLogs/${var.aws_account_id}/*"]
  }


  statement {
    sid     = "DenyNonTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.alb.arn,
      "${aws_s3_bucket.alb.arn}/*",
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

resource "aws_s3_bucket_policy" "web_assets" {
  bucket = aws_s3_bucket.web_assets.id
  policy = data.aws_iam_policy_document.web_assets_cf.json

  depends_on = [aws_s3_bucket_public_access_block.web]
}