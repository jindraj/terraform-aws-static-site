# Terraform module for static site hosting propagating gitlab variables

This module will setup GitLab CI variables for static website deployment.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5, < 2.0 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 18.0, < 19.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | >= 18.0, < 19.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [gitlab_project_variable.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/project_variable) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_extra_gitlab_cicd_variables"></a> [extra\_gitlab\_cicd\_variables](#input\_extra\_gitlab\_cicd\_variables) | n/a | <pre>list(object({<br/>    protected         = optional(bool, false)<br/>    hidden            = optional(bool, false)<br/>    masked            = optional(bool, false)<br/>    raw               = optional(bool, true)<br/>    key               = string<br/>    value             = string<br/>    environment_scope = optional(string, "*")<br/>  }))</pre> | `[]` | no |
| <a name="input_gitlab_project_ids"></a> [gitlab\_project\_ids](#input\_gitlab\_project\_ids) | n/a | `list(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->