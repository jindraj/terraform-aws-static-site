locals {
  gitlab_project_ids    = toset(concat(var.gitlab_project_ids, var.gitlab_project_id != "" ? [var.gitlab_project_id] : []))
  first_project_web_url = length(local.gitlab_project_ids) > 0 ? data.gitlab_project.this[element(keys(data.gitlab_project.this), 0)].web_url : ""
  gitlab_domain         = length(local.gitlab_project_ids) > 0 ? regex("https://([^/]+)/.*", local.first_project_web_url)[0] : ""
}

data "gitlab_project" "this" {
  for_each = local.gitlab_project_ids
  id       = each.value
}

data "aws_iam_openid_connect_provider" "gitlab" {
  count = var.enable_deploy_role ? 1 : 0
  url   = format("https://%s", local.gitlab_domain)
}

data "aws_iam_policy_document" "assume_role" {
  count = var.enable_deploy_role ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "ForAnyValue:StringLike"
      values   = [for repo in local.gitlab_project_ids : format("project_path:%s:ref_type:*:ref:*", data.gitlab_project.this[repo].path_with_namespace)]
      variable = format("%s:sub", local.gitlab_domain)
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.gitlab[0].arn]
      type        = "Federated"
    }
  }
}

data "aws_iam_policy_document" "deploy" {
  count = var.enable_deploy_user || var.enable_deploy_role ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [module.s3_bucket.s3_bucket_arn, "${module.s3_bucket.s3_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:ListInvalidations",
      "cloudfront:GetInvalidation"
    ]
    resources = [module.cdn.cloudfront_distribution_arn]
  }
}

resource "aws_iam_role" "deploy" {
  count              = var.enable_deploy_role ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  name               = "zvirt-${local.main_domain_sanitized}-deploy"
  tags               = var.tags
}

resource "aws_iam_role_policy" "deploy" {
  count  = var.enable_deploy_role ? 1 : 0
  name   = "S3Deploy-CFInvalidate"
  role   = aws_iam_role.deploy[0].id
  policy = data.aws_iam_policy_document.deploy[0].json
}

resource "aws_iam_user" "deploy" {
  count = var.enable_deploy_user ? 1 : 0
  name  = "zvirt-${local.main_domain_sanitized}-deploy"
  tags  = var.tags
}

resource "aws_iam_access_key" "deploy" {
  count = var.enable_deploy_user ? 1 : 0
  user  = aws_iam_user.deploy[0].name
}

resource "aws_iam_user_policy" "deploy" {
  count = var.enable_deploy_user ? 1 : 0

  user   = aws_iam_user.deploy[0].name
  policy = data.aws_iam_policy_document.deploy[0].json
}

module "gitlab" {
  count = length(local.gitlab_project_ids) == 0 ? 0 : 1

  source = "./modules/gitlab"

  gitlab_project_ids = local.gitlab_project_ids

  extra_gitlab_cicd_variables = concat(
    [
      {
        key   = "AWS_S3_BUCKET${var.aws_env_vars_suffix}"
        value = module.s3_bucket.s3_bucket_id
        gitlab_environment = var.gitlab_environment
      },
      {
        key   = "AWS_DEFAULT_REGION${var.aws_env_vars_suffix}"
        value = data.aws_region.current.region
        gitlab_environment = var.gitlab_environment
      },
      {
        key   = "AWS_CF_DISTRIBUTION_ID${var.aws_env_vars_suffix}"
        value = module.cdn.cloudfront_distribution_id
        gitlab_environment = var.gitlab_environment
      },
    ],
    var.enable_deploy_role ? [
      { # CONDITIONAL
        key   = "AWS_ROLE_ARN${var.aws_env_vars_suffix}"
        value = aws_iam_role.deploy[0].arn
        gitlab_environment = var.gitlab_environment
      }
    ] : [],
    var.enable_deploy_user ? [
      { # CONDITIONAL
        key   = "AWS_ACCESS_KEY_ID${var.aws_env_vars_suffix}"
        value = aws_iam_access_key.deploy[0].id
        gitlab_environment = var.gitlab_environment
      },
      { # CONDITIONAL
        key    = "AWS_SECRET_ACCESS_KEY${var.aws_env_vars_suffix}"
        value  = aws_iam_access_key.deploy[0].secret
        masked = true
        gitlab_environment = var.gitlab_environment
      },
    ] : [],
    var.extra_gitlab_cicd_variables
  )
}
