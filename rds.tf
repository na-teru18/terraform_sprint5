# シークレット管理
variable "sercret_password" {
  type        = string
  description = "RDS用のpassword"
  sensitive   = true
}

# セキュリティ・グループ
resource "aws_security_group" "terraform_db_sg" {
  name        = "db-sg"
  description = "Only allow ec2_sg inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.terraform_api_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# DBサブネット・グループ
resource "aws_db_subnet_group" "terraform_db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.terraform_private_subnet_1.id, aws_subnet.terraform_private_subnet_2.id]

  tags = {
    Name = "db-subnet-group"
  }
}

# RDS
resource "aws_db_instance" "terraform_db" {
  identifier             = "db-server"
  allocated_storage      = 10
  db_name                = "dbserver"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = var.sercret_password
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.terraform_db_subnet_group.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.terraform_db_sg.id]
}
