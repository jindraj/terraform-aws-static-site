locals {
  gitlab_moved_blocks = join("\n\n", flatten([
    for pid in var.gitlab_project_ids : [
      <<EOF
moved {
  from = gitlab_project_variable.cloudfront_distribution_id["${pid}"]
  to   = gitlab_project_variable.this["${pid}-AWS_CF_DISTRIBUTION_ID"]
}
EOF
      ,
      <<EOF
moved {
  from = gitlab_project_variable.aws_default_region["${pid}"]
  to   = gitlab_project_variable.this["${pid}-AWS_DEFAULT_REGION"]
}
EOF
      ,
      <<EOF
moved {
  from = gitlab_project_variable.s3_bucket["${pid}"]
  to   = gitlab_project_variable.this["${pid}-AWS_S3_BUCKET"]
}
EOF
      ,
      <<EOF
moved {
  from = gitlab_project_variable.site_aws_access_key_id["${pid}"]
  to   = gitlab_project_variable.this["${pid}-AWS_ACCESS_KEY_ID"]
}
EOF
      ,
      <<EOF
moved {
  from = gitlab_project_variable.site_aws_secret_access_key["${pid}"]
  to   = gitlab_project_variable.this["${pid}-AWS_SECRET_ACCESS_KEY"]
}
EOF
    ]
  ]))
}

output "moved_blocks_gitlab_project_variables" {
  value       = local.gitlab_moved_blocks
  description = "Copy/paste these moved blocks into the root module to avoid recreation."
}
