locals {
  s3_origin_id = "myS3Origin"                     # CloudFrontがS3を識別するための名前
  my_domain    = "cloud-tech-teruya-hands-on.com" # 使用するルート・ドメイン
}

# ACM（AWS Certificate Manager）で事前に発行したSSL/TLS証明書の情報
data "aws_acm_certificate" "terraform_main_domain" {
  region   = "us-east-1"
  domain   = local.my_domain
  statuses = ["ISSUED"]
}

# OAC（Origin Access Control）
resource "aws_cloudfront_origin_access_control" "terraform_oac" {
  name                              = "my-reservation-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # すべてのリクエストに署名
  signing_protocol                  = "sigv4"  # 認証プロトコル
}

# CloudFront ディストリビューション
resource "aws_cloudfront_distribution" "terraform_s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.terraform_s3_web_server.bucket_regional_domain_name # S3バケットを配信元に設定
    origin_access_control_id = aws_cloudfront_origin_access_control.terraform_oac.id             # OACを使用してアクセスを保護
    origin_id                = local.s3_origin_id
  }

  enabled = true
  # is_ipv6_enabled     = true
  # comment             = "Some comment"
  default_root_object = "index.html"

  aliases = [local.my_domain]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
       query_string = false

       cookies {
         forward = "none"
       }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  # ordered_cache_behavior {
  #   path_pattern     = "/content/immutable/*"
  #   allowed_methods  = ["GET", "HEAD", "OPTIONS"]
  #   cached_methods   = ["GET", "HEAD", "OPTIONS"]
  #   target_origin_id = local.s3_origin_id

  #   forwarded_values {
  #     query_string = false
  #     headers      = ["Origin"]

  #     cookies {
  #       forward = "none"
  #     }
  #   }

  #   min_ttl                = 0
  #   default_ttl            = 86400
  #   max_ttl                = 31536000
  #   compress               = true
  #   viewer_protocol_policy = "redirect-to-https"
  # }

  # Cache behavior with precedence 1
  # ordered_cache_behavior {
  #   path_pattern     = "/content/*"
  #   allowed_methods  = ["GET", "HEAD", "OPTIONS"]
  #   cached_methods   = ["GET", "HEAD"]
  #   target_origin_id = local.s3_origin_id

  #   forwarded_values {
  #     query_string = false

  #     cookies {
  #       forward = "none"
  #     }
  #   }

  #   min_ttl                = 0
  #   default_ttl            = 3600
  #   max_ttl                = 86400
  #   compress               = true
  #   viewer_protocol_policy = "redirect-to-https"
  # }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "JP"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.terraform_main_domain.arn
    ssl_support_method  = "sni-only"
  }
}
