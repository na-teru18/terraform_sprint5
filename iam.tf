# Assumeロール（信頼ポリシー）
data "aws_iam_policy_document" "terraform_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAMロール
resource "aws_iam_role" "terraform_ecs_ecr_role" {
  name               = "ECR-access-role"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role.json
}

# IAMポリシー（AWS管理ポリシーのためdataで取得）
data "aws_iam_policy_document" "terraform_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchImportUpstreamImage"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_ecs_policy" {
  name        = "ECR-access-policy"
  description = "ECS access ECR images"
  policy      = data.aws_iam_policy_document.terraform_policy.json
}

# IAMロールにIAMポリシーをアタッチする
resource "aws_iam_role_policy_attachment" "terraform_policy_attach" {
  role       = aws_iam_role.terraform_ecs_ecr_role.name
  policy_arn = aws_iam_policy.terraform_ecs_policy.arn
}