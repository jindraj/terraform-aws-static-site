module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.0.2"

  aliases             = concat(var.domains, keys(var.extra_domains))
  comment             = local.main_domain
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  web_acl_id          = var.waf_acl_arn

  custom_error_response = local.oidc_enabled ? [] : [
    {
      error_caching_min_ttl = 3000
      error_code            = 403
      response_code         = var.override_status_code_403
      response_page_path    = "/index.html"
    },
    {
      error_caching_min_ttl = 3000
      error_code            = 404
      response_code         = var.override_status_code_404
      response_page_path    = "/index.html"
    }
  ]

  default_cache_behavior = {
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    target_origin_id           = var.s3_bucket_name
    response_headers_policy_id = local.custom_headers ? aws_cloudfront_response_headers_policy.this[0].id : null
    viewer_protocol_policy     = "redirect-to-https"
    default_ttl                = var.default_ttl
    min_ttl                    = var.min_ttl
    max_ttl                    = var.max_ttl

    # verify?
    forwarded_values = {
      query_string = false
      cookies = {
        forward = local.oidc_enabled ? "all" : "none"
      }
    }

    lambda_function_association = module.oidc.lambda_edge_function_arn == null ? {} : {
      viewer-request = {
        lambda_arn   = module.oidc.lambda_edge_function_arn
        include_body = false
      }
    }

    function_association = {
      for k, arn in {
        "viewer-request"  = var.functions.viewer_request
        "viewer-response" = var.functions.viewer_response
      } : k => { function_arn = arn } if arn != null
    }
  }

  logging_config = var.logs_bucket_domain_name == null ? null : {
    bucket          = var.logs_bucket_domain_name
    prefix          = "cloudfront/access_logs/${local.main_domain_sanitized}/"
    include_cookies = false
  }

  ordered_cache_behavior = concat(
    [],
    local.oidc_enabled ? [
      {
        path_pattern             = "/callback*"
        target_origin_id         = "api-gateway-origin"
        allowed_methods          = ["GET", "HEAD", "OPTIONS"]
        cached_methods           = ["GET", "HEAD"]
        viewer_protocol_policy   = "redirect-to-https"
        compress                 = true
        cache_policy_id          = aws_cloudfront_cache_policy.oidc[0].id
        origin_request_policy_id = aws_cloudfront_origin_request_policy.oidc[0].id
      }
    ] : [],
    [
      for p in var.proxy_paths : {
        path_pattern = "${trim(p.path_prefix, "/")}/*" # safe variant: "/${trim(p.path_prefix, "/")}/*"

        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD", "OPTIONS"]
        target_origin_id = p.origin_domain

        viewer_protocol_policy = "redirect-to-https"

        origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_all_viewer_and_cloudfront_headers.id
        cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_disabled.id
      }
    ]
  )

  origin = merge(
    {
      s3_bucket = {
        domain_name               = module.s3_bucket.s3_bucket_bucket_regional_domain_name
        origin_access_control_key = "s3"
        origin_id                 = var.s3_bucket_name
        origin_path               = var.origin_path
      }
    },
    local.oidc_enabled ? {
      oidc_callback = {
        domain_name = split("/", module.oidc.oidc_callback_url_base)[2]
        origin_id   = "api-gateway-origin"
        custom_origin_config = {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
    } : {},
    {
      for i, p in var.proxy_paths : "proxy_${i}" => {
        domain_name = p.origin_domain
        origin_id   = p.origin_domain
        origin_path = startswith(p.path_prefix, "/") ? p.path_prefix : "/${p.path_prefix}"

        custom_origin_config = {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2", "TLSv1.1"]
        }
      }
    }
  )

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

  tags = local.tags

  viewer_certificate = {
    cloudfront_default_certificate = false
    acm_certificate_arn            = module.certificate.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2018"
  }
}
