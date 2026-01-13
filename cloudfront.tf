module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.0.2"

  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  default_root_object = "index.html"

  aliases = concat(var.domains, keys(var.extra_domains))
  comment = local.main_domain

  custom_error_response = length(var.oidc) > 0 ? [] : [
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

  # TODO: dynamic ordered_cache_behavior 2x ruzna pro var.oidc a var.proxy_paths
  # ordered_cache_behavior list(object({ allowed_methods = optional(list(string), ["GET", "HEAD", "OPTIONS"]) cached_methods = optional(list(string), ["GET", "HEAD"]) cache_policy_id = optional(string) cache_policy_name = optional(string) compress = optional(bool, true) default_ttl = optional(number) field_level_encryption_id = optional(string) forwarded_values = optional(object({ cookies = object({ forward = optional(string, "none") whitelisted_names = optional(list(string)) }) headers = optional(list(string)) query_string = optional(bool, false) query_string_cache_keys = optional(list(string)) }), { cookies = { forward = "none" } query_string = false } ) function_association = optional(map(object({ event_type = optional(string) function_arn = optional(string) function_key = optional(string) }))) grpc_config = optional(object({ enabled = optional(bool) })) lambda_function_association = optional(map(object({ event_type = optional(string) include_body = optional(bool) lambda_arn = string }))) max_ttl = optional(number) min_ttl = optional(number) origin_request_policy_id = optional(string) origin_request_policy_name = optional(string) path_pattern = string realtime_log_config_arn = optional(string) response_headers_policy_id = optional(string) response_headers_policy_key = optional(string) response_headers_policy_name = optional(string) smooth_streaming = optional(bool) target_origin_id = string trusted_key_groups = optional(list(string)) trusted_signers = optional(list(string)) viewer_protocol_policy = string }))

  ordered_cache_behavior = concat(
    [],
    length(var.oidc) == 0 ? [] : [
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
    ]
  )

  origin = {
    s3_bucket = {
      domain_name               = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      origin_id                 = var.s3_bucket_name
      origin_path               = var.origin_path
      origin_access_control_key = "s3"
    }
    oidc_callback = length(var.oidc) == 0 ? null : {
      domain_name = split("/", module.oidc.oidc_callback_url_base)[2]
      origin_id   = "api-gateway-origin"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
    # TODO: tady budou dalsi dynamicky originy
    # iterovany for/for_each nad var.proxy.paths
    # a take var.oidc
  }

  origin_access_control = {
    s3 = {
      name             = "Access from CF to S3 - ${local.main_domain}"
      description      = "Access from CF to S3 - ${local.main_domain}"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
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

  logging_config = var.logs_bucket_domain_name == null ? null : {
    bucket          = var.logs_bucket_domain_name
    prefix          = "cloudfront/access_logs/${local.main_domain_sanitized}/"
    include_cookies = false
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
