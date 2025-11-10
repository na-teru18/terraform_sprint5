# GitHubのディレクトリ
locals {
  dir_path = "cloudtech-reservation-web/"
}

# S3バケット
resource "aws_s3_bucket" "terraform_s3_web_server" {
  bucket        = "teruya-web-server-bucket-1"
  force_destroy = true

  tags = {
    Name        = "WebServerBucket"
    Environment = "Dev"
  }
}

# S3ブロックパブリックアクセスの設定
resource "aws_s3_bucket_public_access_block" "terraform_s3_public_access_block" {
  bucket = aws_s3_bucket.terraform_s3_web_server.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# GitHubに保存されているファイルをアップロード
resource "aws_s3_object" "terraform_github_object" {
  bucket = aws_s3_bucket.terraform_s3_web_server.id

  for_each = fileset(local.dir_path, "**/*")
  # S3へファイルをアップロードするときのkey値
  key = each.value
  # ファイルのローカルパス
  source = "${local.dir_path}${each.value}"
  # Content-Typeを動的に設定
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
  }, element(split(".", each.value), length(split(".", each.value)) -1), -1)

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${local.dir_path}${each.value}")
}

# S3バケット・ポリシー（※S3バケットに適用するアクセスルール（ポリシー）の内容を定義する）
# See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
data "aws_iam_policy_document" "terraform_origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.terraform_s3_web_server.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.terraform_s3_distribution.arn]
    }
  }
}

# S3バケットとバケット・ポリシーを関連付ける
resource "aws_s3_bucket_policy" "terraform_s3_bucket_policy" {
  bucket = aws_s3_bucket.terraform_s3_web_server.bucket
  policy = data.aws_iam_policy_document.terraform_origin_bucket_policy.json
}

