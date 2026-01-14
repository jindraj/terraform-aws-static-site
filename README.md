# Terraform module for static site hosting

This module will create S3 bucket as storage for site and connect it with CloudFront for exposing it to public. It also creates TLS certificates for it.

## Usage

```terraform
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "static-site" {
  source  = "cookielab/static-site/aws"
  version = "~> 2.1"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  domains        = ["www.example.com"]
  domain_zone_id = aws_route53_zone.example_com.zone_id
  s3_bucket_name = "example_com_web"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5, < 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.0, < 19.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.61.0 |
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | 17.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cdn"></a> [cdn](#module\_cdn) | terraform-aws-modules/cloudfront/aws | 6.3.0 |
| <a name="module_certificate"></a> [certificate](#module\_certificate) | terraform-aws-modules/acm/aws | 6.3.0 |
| <a name="module_gitlab"></a> [gitlab](#module\_gitlab) | ./modules/gitlab | n/a |
| <a name="module_oidc"></a> [oidc](#module\_oidc) | ./modules/oidc | n/a |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | 5.10.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_cache_policy.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_origin_request_policy.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_request_policy) | resource |
| [aws_cloudfront_response_headers_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy) | resource |
| [aws_iam_access_key.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_role.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_user.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudfront_cache_policy.managed_caching_disabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_origin_request_policy.managed_all_viewer_and_cloudfront_headers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |
| [aws_iam_openid_connect_provider.gitlab](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [gitlab_project.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cache_ttl"></a> [cache\_ttl](#input\_cache\_ttl) | Cache TTLs configuration for CloudFront distribition; sets minimum/maximum and default amount of time the objects stays in cache | <pre>object({<br/>    min     = optional(number, 0)<br/>    max     = optional(number, 86400)<br/>    default = optional(number, 3600)<br/>  })</pre> | `{}` | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | CloudFront price class | `string` | `"PriceClass_100"` | no |
| <a name="input_custom_headers"></a> [custom\_headers](#input\_custom\_headers) | n/a | <pre>object({<br/>    headers = optional(map(object({<br/>      override = optional(bool, true)<br/>      value    = string<br/>    })))<br/>    cors_rules = optional(object({<br/>      use             = optional(bool, false)<br/>      allowed_headers = optional(list(string))<br/>      allowed_methods = optional(list(string))<br/>      allowed_origins = optional(list(string))<br/>      expose_headers  = optional(list(string))<br/>      max_age_seconds = optional(number)<br/>      override        = optional(bool, true)<br/>    }), null)<br/>    frame_options = optional(object({<br/>      use          = optional(bool, false)<br/>      frame_option = string<br/>      override     = optional(bool, true)<br/>    }), null)<br/>    referrer_policy = optional(object({<br/>      use             = optional(bool, false)<br/>      referrer_policy = string<br/>      override        = optional(bool, true)<br/>    }), null)<br/>    xss_protection = optional(object({<br/>      use        = optional(bool, false)<br/>      mode_block = bool<br/>      protection = bool<br/>      override   = optional(bool, true)<br/>    }), null)<br/>    content_security_policy = optional(object({<br/>      use      = optional(bool, false)<br/>      policy   = string<br/>      override = optional(bool, true)<br/>    }), null)<br/>    strict_transport_security = optional(object({<br/>      use                        = optional(bool, false)<br/>      access_control_max_age_sec = string<br/>      include_subdomains         = bool<br/>      preload                    = bool<br/>      override                   = optional(bool, true)<br/>    }), null)<br/>    content_type_options = optional(object({<br/>      override = optional(bool, true)<br/>    }), null)<br/>  })</pre> | `null` | no |
| <a name="input_domain_zone_id"></a> [domain\_zone\_id](#input\_domain\_zone\_id) | Deprecated!  Use `zones_and_domains`.The ID of the hosted zone for domain | `string` | `null` | no |
| <a name="input_domains"></a> [domains](#input\_domains) | Deprecated! Use `zones_and_domains`. List of domain aliases. You can also specify wildcard eg.: `*.example.com` | `list(string)` | `[]` | no |
| <a name="input_enable_deploy_role"></a> [enable\_deploy\_role](#input\_enable\_deploy\_role) | Toggle IAM role creation for S3 deploy & CloudFront invalidation; This requires existing aws\_iam\_openid\_connect\_provider matching domain of your gitlab provider | `bool` | `false` | no |
| <a name="input_enable_deploy_user"></a> [enable\_deploy\_user](#input\_enable\_deploy\_user) | Toggle s3 deploy user creation | `bool` | `true` | no |
| <a name="input_encrypt_with_kms"></a> [encrypt\_with\_kms](#input\_encrypt\_with\_kms) | Enable server side s3 bucket encryption with KMS key | `bool` | `false` | no |
| <a name="input_extra_domains"></a> [extra\_domains](#input\_extra\_domains) | Deprecated! Use `zones_and_domains`. Map of extra\_domains with domain name and zone\_id; This input can be kept initialy for moved blocks generaiton | `map(string)` | `{}` | no |
| <a name="input_extra_gitlab_cicd_variables"></a> [extra\_gitlab\_cicd\_variables](#input\_extra\_gitlab\_cicd\_variables) | List of additional gitlab CI/CD variables | <pre>list(object({<br/>    protected = optional(bool, false)<br/>    masked    = optional(bool, false)<br/>    raw       = optional(bool, true)<br/>    key       = string<br/>    value     = string<br/>  }))</pre> | `[]` | no |
| <a name="input_functions"></a> [functions](#input\_functions) | n/a | <pre>object({<br/>    viewer_request  = optional(string)<br/>    viewer_response = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_gitlab_aws_env_vars_suffix"></a> [gitlab\_aws\_env\_vars\_suffix](#input\_gitlab\_aws\_env\_vars\_suffix) | Append suffix for Gitlab CI/CD environment variables if needed | `string` | `""` | no |
| <a name="input_gitlab_environment"></a> [gitlab\_environment](#input\_gitlab\_environment) | GitLab environment name | `string` | `"*"` | no |
| <a name="input_gitlab_project_ids"></a> [gitlab\_project\_ids](#input\_gitlab\_project\_ids) | Integrates with GitLab CI/CD to deploy site and invalidate CloudFront cache | `list(string)` | `[]` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key | `number` | `30` | no |
| <a name="input_kms_key_policy"></a> [kms\_key\_policy](#input\_kms\_key\_policy) | Additional KSM key policy | `string` | `"{}"` | no |
| <a name="input_logs_bucket"></a> [logs\_bucket](#input\_logs\_bucket) | Bucket to store CloudFront logs | `string` | `null` | no |
| <a name="input_logs_bucket_domain_name"></a> [logs\_bucket\_domain\_name](#input\_logs\_bucket\_domain\_name) | n/a | `string` | `null` | no |
| <a name="input_oidc"></a> [oidc](#input\_oidc) | List of OIDC providers | <pre>list(object({<br/>    application_name = string<br/>    application_id   = string<br/>    client_secret    = string<br/>    auth_url         = string<br/>    token_url        = string<br/>    session_druation = optional(number, 12 * 3600)<br/>  }))</pre> | `[]` | no |
| <a name="input_origin_path"></a> [origin\_path](#input\_origin\_path) | Cloudfront origin path | `string` | `""` | no |
| <a name="input_override_status_code_403"></a> [override\_status\_code\_403](#input\_override\_status\_code\_403) | Override status code for 403 error | `number` | `403` | no |
| <a name="input_override_status_code_404"></a> [override\_status\_code\_404](#input\_override\_status\_code\_404) | Override status code for 404 error | `number` | `200` | no |
| <a name="input_proxy_paths"></a> [proxy\_paths](#input\_proxy\_paths) | n/a | <pre>list(object({<br/>    origin_domain = string<br/>    path_prefix   = string<br/>  }))</pre> | `[]` | no |
| <a name="input_response_header_access_control_allow_credentials"></a> [response\_header\_access\_control\_allow\_credentials](#input\_response\_header\_access\_control\_allow\_credentials) | n/a | `bool` | `false` | no |
| <a name="input_response_header_origin_override"></a> [response\_header\_origin\_override](#input\_response\_header\_origin\_override) | n/a | `bool` | `false` | no |
| <a name="input_restriction_type"></a> [restriction\_type](#input\_restriction\_type) | Apply for geo restrictions, values: none, whitelist, blacklist | `string` | `"none"` | no |
| <a name="input_restrictions_locations"></a> [restrictions\_locations](#input\_restrictions\_locations) | List of country codes | `list(string)` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | The name for the S3 bucket hosting the website | `string` | n/a | yes |
| <a name="input_s3_bucket_policy"></a> [s3\_bucket\_policy](#input\_s3\_bucket\_policy) | Additional S3 bucket policy | `string` | `"{}"` | no |
| <a name="input_s3_cors_rule"></a> [s3\_cors\_rule](#input\_s3\_cors\_rule) | List of maps containing rules for Cross-Origin Resource Sharing. | <pre>list(object({<br/>    allowed_headers = optional(list(string))<br/>    allowed_methods = optional(list(string))<br/>    allowed_origins = optional(list(string))<br/>    expose_headers  = optional(list(string))<br/>    max_age_seconds = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_waf_acl_arn"></a> [waf\_acl\_arn](#input\_waf\_acl\_arn) | WAF ACL ARN | `string` | `null` | no |
| <a name="input_zones_and_domains"></a> [zones\_and\_domains](#input\_zones\_and\_domains) | Ordered list of Route53 with zone\_id list of domain aliases. The first item is used as the main domain. | <pre>list(object({<br/>    zone_id = string<br/>    domains = list(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_access_key_id"></a> [aws\_access\_key\_id](#output\_aws\_access\_key\_id) | n/a |
| <a name="output_aws_cloudfront_distribution_id"></a> [aws\_cloudfront\_distribution\_id](#output\_aws\_cloudfront\_distribution\_id) | n/a |
| <a name="output_aws_s3_bucket_arn"></a> [aws\_s3\_bucket\_arn](#output\_aws\_s3\_bucket\_arn) | n/a |
| <a name="output_aws_s3_bucket_name"></a> [aws\_s3\_bucket\_name](#output\_aws\_s3\_bucket\_name) | n/a |
| <a name="output_aws_s3_bucket_regional_domain_name"></a> [aws\_s3\_bucket\_regional\_domain\_name](#output\_aws\_s3\_bucket\_regional\_domain\_name) | n/a |
| <a name="output_aws_secret_access_key"></a> [aws\_secret\_access\_key](#output\_aws\_secret\_access\_key) | n/a |
| <a name="output_moved_blocks_aws_route53_records"></a> [moved\_blocks\_aws\_route53\_records](#output\_moved\_blocks\_aws\_route53\_records) | n/a |
| <a name="output_moved_blocks_gitlab_project_variables"></a> [moved\_blocks\_gitlab\_project\_variables](#output\_moved\_blocks\_gitlab\_project\_variables) | Copy/paste these moved blocks into the root module to avoid recreation. |
| <a name="output_oidc_callback_url"></a> [oidc\_callback\_url](#output\_oidc\_callback\_url) | n/a |
| <a name="output_s3_kms_key_arn"></a> [s3\_kms\_key\_arn](#output\_s3\_kms\_key\_arn) | n/a |
<!-- END_TF_DOCS -->
