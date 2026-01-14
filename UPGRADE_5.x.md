# Upgrade from v4.x to v5.x

## project_id is 

Old

```terraform
module "static-site" {
  source  = "cookielab/static-site/aws"
  version = "~> 4.0"

  domains        = ["example.com", "www.example.com"]
  domain_zone_id = data.aws_route53_zone.example_com.zone_id
  
  extra_domains = {
    "example.net"     = data.aws_route53_zone.example_net.zone_id
    "www.example.net" = data.aws_route53_zone.example_net.zone_id
    "example.org"     = data.aws_route53_zone.example_org.zone_id
    "www.example.org" = data.aws_route53_zone.example_org.zone_id
  }

  project_id = "123"

  aws_env_vars_suffix = "_new"

  min_ttl     = 0
  max_ttl     = 86400
  default_ttl = 3600
}
```

New

```terraform
module "static-site" {
  source  = "cookielab/static-site/aws"
  version = "~> 5.0"

  zones_and_domains = [
    {
      zone_id = data.aws_route53_zone.example_com.zone_id
      domains = ["example.com", "www.example.com"]
    },
    {
      zone_id = data.aws_route53_zone.example_net.zone_id
      domains = ["example.net", "www.example.net"]
    },
    {
      zone_id = data.aws_route53_zone.example_org.zone_id
      domains = ["example.org", "www.example.org"]
    }
  ]

  project_ids = ["123"]

  gitlab_aws_env_vars_suffix = "_new"

  cache_ttl = {
    min     = 0
    max     = 86400
    default = 3600
  }
}
```
