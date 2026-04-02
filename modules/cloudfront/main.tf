

resource "aws_cloudfront_origin_access_control" "web" {
    name = "${var.name_prefix}-web-assets-oac"

    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"

}
resource "aws_cloudfront_distribution" "web_assets" {
    enabled             = true
    is_ipv6_enabled     = true
    default_root_object = "index.html"
    price_class         = var.price_class

    origin {
      domain_name = var.s3_bucket_regional_domain
      origin_id   = "s3-web-assets"
      origin_access_control_id = aws_cloudfront_origin_access_control.web.id
    }

    # Default cache behavior for HTML/assets
    default_cache_behavior {
      target_origin_id = "s3-web-assets"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD"]
      compress = true

      cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      
    }

    custom_error_response {
      error_code = 404
      response_code = 200
      response_page_path = "/index.html"
      error_caching_min_ttl = 10
    }

    custom_error_response {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    }

      viewer_certificate {
      # If no custom domain: use CloudFront default certificate
      # If custom domain: set acm_certificate_arn + ssl_support_method below
      cloudfront_default_certificate = length(var.domain_aliases) == 0 ? true : false
      acm_certificate_arn            = length(var.domain_aliases) > 0 ? var.acm_certificate_arn : null
      ssl_support_method             = length(var.domain_aliases) > 0 ? "sni-only" : null
      minimum_protocol_version       = length(var.domain_aliases) > 0 ? "TLSv1.2_2021" : null
    }

    restrictions {
      geo_restriction {
        restriction_type = "none"
      }
    }

    # ---------------------------------------------------------------------------
    # Access logging
    # ---------------------------------------------------------------------------
    logging_config {
      bucket          = var.s3_log_bucket_domain
      prefix          = "cloudfront/"
      include_cookies = false
    }

    tags = { Name = "${var.name_prefix}-cf-distribution" }

}