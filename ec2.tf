# EC2
resource "aws_instance" "terraform_bation_server" {
  ami           = "ami-0cae6d6fe6048ca2c"
  instance_type = "t3.micro"
  # key_name                    = aws_key_pair.terraform_my_key_pair.key_name
  security_groups             = [aws_security_group.terraform_ec2_sg.id]
  subnet_id                   = aws_subnet.terraform_public_subnet_1.id
  associate_public_ip_address = true

  depends_on = [aws_db_instance.terraform_db]

  user_data = <<-EOF
#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "=== UserData開始 ==="

# MySQLクライアントのインストール 
sudo yum update -y
sudo yum install -y https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
sudo yum install mysql-community-server -y
sudo systemctl enable mysqld
sudo systemctl start mysqld

# RDS接続情報
RDS_HOST="${aws_db_instance.terraform_db.address}"
DB_USER="${aws_db_instance.terraform_db.username}"
DB_PASSWORD="${aws_db_instance.terraform_db.password}"
DB_NAME="${aws_db_instance.terraform_db.db_name}"

# スキーマとテーブルの作成
SQL_COMMANDS=$(cat <<EOF
CREATE DATABASE IF NOT EXISTS $${DB_NAME};
CREATE TABLE IF NOT EXISTS $${DB_NAME}.Reservations (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    reservation_date DATE NOT NULL,
    number_of_people INT NOT NULL
);
INSERT INTO $${DB_NAME}.Reservations (company_name, reservation_date, number_of_people)
VALUES ('株式会社テスト', '2024-04-21', 5);
SELECT * FROM reservation_db.Reservations;
EOF)

# RDSに接続
export MYSQL_PWD=$${DB_PASSWORD}
echo "$${SQL_COMMANDS}"  |  mysql -h $${RDS_HOST} -P 3306 -u $${DB_USER}

# SQL実行コマンドの終了ステータスを確認(RDS接続を切断)
SQL_EXIT_CODE=$?

# 実行結果の確認
if [ $${SQL_EXIT_CODE} -eq 0 ]; then
    echo "RDSへの接続とテーブル作成に成功しました。"
else
    echo "RDSへの接続またはテーブル作成に失敗しました。" >&2
fi

exit 0
EOF

  tags = {
    Name = "bation-server"
  }
}

# Elastic IP
resource "aws_eip" "ec2_eip" {
  instance = aws_instance.terraform_bation_server.id
  domain   = "vpc"
  tags = {
    Name = "public_gip"
  }
}
