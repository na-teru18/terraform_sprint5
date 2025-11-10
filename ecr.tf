resource "aws_ecr_repository" "terraform_ecr" {
  name                 = "reservation-ecr"
  image_tag_mutability = "MUTABLE" # イメージを上書きできるようにするか否か

  encryption_configuration {
    encryption_type = "AES256" # 暗号化の設定
  }

  image_scanning_configuration {
    scan_on_push = false # イメージがリポジトリにプッシュされた後に自動的にスキャン
  }
}