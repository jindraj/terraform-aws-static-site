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

output "moved_blocks_gitlab_project_variables" {
  value = try(module.gitlab[0].moved_blocks_gitlab_project_variables, "")
}
