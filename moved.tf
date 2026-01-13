moved {
  from = aws_cloudfront_distribution.this
  to   = module.cdn.aws_cloudfront_distribution.this[0]
}
moved {
  from = aws_cloudfront_origin_access_control.this
  to   = module.cdn.aws_cloudfront_origin_access_control.this["s3"]
}
