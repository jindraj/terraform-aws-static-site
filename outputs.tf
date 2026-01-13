output "aws_s3_bucket_name" {
  value = module.s3_bucket.s3_bucket_id
}

output "aws_cloudfront_distribution_id" {
  value = module.cdn.cloudfront_distribution_id
  #value = aws_cloudfront_distribution.this.id
}

output "aws_access_key_id" {
  value = var.enable_deploy_user ? aws_iam_access_key.deploy[0].id : null
}

output "aws_secret_access_key" {
  value     = var.enable_deploy_user ? aws_iam_access_key.deploy[0].secret : null
  sensitive = true
}

output "aws_s3_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "aws_s3_bucket_regional_domain_name" {
  value = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}

output "s3_kms_key_arn" {
  value = var.encrypt_with_kms ? aws_kms_key.this[0].arn : null
}

output "oidc_callback_url" {
  value = module.oidc.oidc_callback_url_base != null ? module.oidc.oidc_callback_url_base : null
}

output "route53_moved_blocks" {
  value = join("\n\n", 
    [
      for d, _ in var.extra_domains :
      <<EOF
moved {
  from = aws_route53_record.extra["${d}"]
  to   = aws_route53_record.this["${d}"]
}
EOF
    ]
  )
}

output "gitlab_project_variable_moved_blocks" {
  value = join("\n\n", flatten([
    for pid in var.gitlab_project_ids : [
      <<EOF
moved {
  from = gitlab_project_variable.aws_default_region["${pid}"]
  to   = gitlab_project_variable.extra["${pid}-AWS_DEFAULT_REGION"]
}
EOF
      ,
      <<EOF
moved {
  from = gitlab_project_variable.cloudfront_distribution_id["${pid}"]
  to   = gitlab_project_variable.extra["${pid}-AWS_CF_DISTRIBUTION_ID"]
}
EOF
      ,
      <<EOF
moved {
  from = gitlab_project_variable.s3_bucket["${pid}"]
  to   = gitlab_project_variable.extra["${pid}-AWS_S3_BUCKET"]
}
EOF
      ,
      <<EOF
moved {
  from = gitlab_project_variable.site_aws_access_key_id["${pid}"]
  to   = gitlab_project_variable.extra["${pid}-AWS_ACCESS_KEY_ID"]
}
EOF
      ,
      <<EOF
moved {
  from = gitlab_project_variable.site_aws_secret_access_key["${pid}"]
  to   = gitlab_project_variable.extra["${pid}-AWS_SECRET_ACCESS_KEY"]
}
EOF
    ]
  ]))
}
