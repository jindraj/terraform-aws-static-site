module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.0.2"

  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  default_root_object = "index.html"

  aliases = concat(var.domains, keys(var.extra_domains))
  comment = local.main_domain

  origin = {
    s3_bucket = {
      domain_name               = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      origin_id                 = var.s3_bucket_name
      origin_path               = var.origin_path
      origin_access_control_key = "s3"
    }
    # TODO: tady budou dalsi dynamicky originy
    # iterovany for/for_each nad var.proxy.paths
    # a take var.oidc
  }

  default_cache_behavior = {
    target_origin_id           = var.s3_bucket_name
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    response_headers_policy_id = local.custom_headers ? aws_cloudfront_response_headers_policy.this[0].id : null
    compress                   = true
    # verify?
    forwarded_values = {
      query_string = false
      cookies = {
        forward = length(var.oidc) == 0 ? "none" : "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl

    lambda_function_association = module.oidc.lambda_edge_function_arn == null ? {} : {
      viewer-request = {
        lambda_arn   = module.oidc.lambda_edge_function_arn
        include_body = false
      }
    }

  }

  custom_error_response = length(var.oidc) > 0 ? [] : [
    {
      error_code         = 404
      response_code      = var.override_status_code_404
      response_page_path = "/index.html"
    },
    {
      error_code         = 403
      response_code      = var.override_status_code_403
      response_page_path = "/index.html"
    }
  ]

  # TODO: dynamic ordered_cache_behavior 2x ruzna pro var.oidc a var.proxy_paths
  # TODO: dynamic logging_config

  origin_access_control = {
    s3 = {
      name             = "Access from CF to S3 - ${local.main_domain}"
      description      = "Access from CF to S3 - ${local.main_domain}"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  restrictions = {
    geo_restriction = {
      restriction_type = var.restriction_type
      locations        = var.restrictions_locations
    }
  }

  viewer_certificate = {
    cloudfront_default_certificate = false
    acm_certificate_arn            = module.certificate.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2018"
  }

  web_acl_id = var.waf_acl_arn

  tags = local.tags
}

# TODO: aws_cloudfront_response_headers_policy
# TODO: DATA aws_cloudfront_origin_request_policy
# TODO: DATA aws_cloudfront_cache_policy
# TODO: aws_cloudfront_cache_policy pro var.oidc
# TODO: aws_cloudfront_origin_request_policy pro var.oidc

moved {
  from = aws_cloudfront_distribution.this
  to   = module.cdn.aws_cloudfront_distribution.this[0]
}
moved {
  from = aws_cloudfront_origin_access_control.this
  to   = module.cdn.aws_cloudfront_origin_access_control.this["s3"]
}
