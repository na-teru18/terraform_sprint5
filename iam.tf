# ----------------------------------------------------
# ECS Task Execution Role (タスク実行ロール)
# FargateがECRからイメージをプルし、CloudWatch Logsにログを書き込むために必要
# ----------------------------------------------------

# 信頼ポリシー
data "aws_iam_policy_document" "terraform_ecs_tasks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS タスク実行ロール
resource "aws_iam_role" "terraform_ecs_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.terraform_ecs_tasks_assume_role_policy.json
}

# AWS管理ポリシー (ECR, CloudWatch Logsへのアクセス権) をアタッチ
resource "aws_iam_role_policy_attachment" "terraform_ecs_task_execution_role_policy_attach" {
  role       = aws_iam_role.terraform_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ----------------------------------------------------
# ECS Task Role (タスクロール)
# アプリケーションがDBパスワードや環境変数などのシークレットにアクセスするために必要
# ----------------------------------------------------

# ECS タスクロール
resource "aws_iam_role" "terraform_ecs_task_role" {
  name               = "ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.terraform_ecs_tasks_assume_role_policy.json
}

# シークレットへの読み取りアクセスを許可するポリシー
data "aws_iam_policy_document" "terraform_ecs_task_secrets_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect    = "Allow"
    # 実際にはアクセスするシークレットのARNを指定することを推奨
    resources = ["*"] 
  }
}

# タスクロールにカスタムポリシーをアタッチ
resource "aws_iam_role_policy" "ecs_task_secrets_policy_attachment" {
  name   = "ecs-task-secrets-access"
  role   = aws_iam_role.terraform_ecs_task_role.id
  policy = data.aws_iam_policy_document.terraform_ecs_task_secrets_policy.json
}