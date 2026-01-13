variable "gitlab_project_ids" {
  type = list(string)
}

variable "extra_gitlab_cicd_variables" {
  type = list(object({
    protected         = optional(bool, false)
    hidden            = optional(bool, false)
    masked            = optional(bool, false)
    raw               = optional(bool, true)
    key               = string
    value             = string
    environment_scope = optional(string, "*")
  }))
  default = []
}
