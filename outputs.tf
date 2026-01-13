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
  value       = "Run following output through `sed -i s/PLACEHOLDER/YOUR_MODULE_NAME/` to generate moved blocks\n\n${join("\n\n", 
    [
      for d, _ in var.extra_domains :
      <<EOF
moved {
  from = module.PLACEHOLDER.aws_route53_record.extra["${d}"]
  to   = module.PLACEHOLDER.aws_route53_record.this["${d}"]
}
EOF
    ]
  )}"
}

locals {
  gitlab_moved_blocks = join("\n\n", flatten([
    for p in var.gitlab_project_ids : [
      <<EOF
moved {
  from = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.cloudfront_distribution_id["${p}"]
  to   = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.this["${p}-AWS_CF_DISTRIBUTION_ID"]
}
EOF
      ,
      <<EOF
moved {
  from = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.aws_default_region["${p}"]
  to   = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.this["${p}-AWS_DEFAULT_REGION"]
}
EOF
      ,
      <<EOF
moved {
  from = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.s3_bucket["${p}"]
  to   = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.this["${p}-AWS_S3_BUCKET"]
}
EOF
      ,
      <<EOF
moved {
  from = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.site_aws_access_key_id["${p}"]
  to   = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.this["${p}-AWS_ACCESS_KEY_ID"]
}
EOF
      ,
      <<EOF
moved {
  from = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.site_aws_secret_access_key["${p}"]
  to   = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.this["${p}-AWS_SECRET_ACCESS_KEY"]
}
EOF
      ,
      <<EOF
moved {
  from = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.site_aws_role_arn["${p}"]
  to   = module.PLACEHOLDER.module.gitlab[0].gitlab_project_variable.this["${p}-AWS_ROLE_ARN"]
}
EOF
    ]
  ]))
}

output "moved_blocks_gitlab_project_variables" {
  value       = "Run following output through `sed -i s/PLACEHOLDER/YOUR_MODULE_NAME/` to generate moved blocks\n\n${local.gitlab_moved_blocks}"
  description = "Copy/paste these moved blocks into the root module to avoid recreation."
}
