locals {
  my_main_domain = "cloud-tech-teruya-hands-on.com" # 使用するルート・ドメイン
  my_sub_domain  = "api.cloud-tech-teruya-hands-on.com"
}

# Create Route53 records for the CloudFront distribution aliases
data "aws_route53_zone" "terraform_main_domain" {
  name = local.my_main_domain
  private_zone = false
}

resource "aws_route53_record" "cloudfront" {
  for_each = aws_cloudfront_distribution.terraform_s3_distribution.aliases
  zone_id  = data.aws_route53_zone.terraform_main_domain.zone_id
  name     = each.value
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.terraform_s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.terraform_s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Create Route53 records for the ALB aliases
resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.terraform_main_domain.zone_id
  name    = local.my_sub_domain
  type    = "A"

  alias {
    name                   = aws_lb.terraform_alb.dns_name
    zone_id                = aws_lb.terraform_alb.zone_id
    evaluate_target_health = true
  }
}
