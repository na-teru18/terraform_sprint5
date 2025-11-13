# VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/21"
  tags = {
    Name = "reservation-vpc"
  }
}

# Subnet
resource "aws_subnet" "terraform_public_subnet_1" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "web-subnet-01"
  }
}

resource "aws_subnet" "terraform_public_subnet_2" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1d"
  tags = {
    Name = "elb-subnet-01"
  }
}

resource "aws_subnet" "terraform_public_subnet_3" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "elb-subnet-02"
  }
}

resource "aws_subnet" "terraform_private_subnet_3" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1d"
  tags = {
    Name = "api-subnet-01"
  }
}

resource "aws_subnet" "terraform_private_subnet_4" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "api-subnet-02"
  }
}


resource "aws_subnet" "terraform_private_subnet_1" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1d"
  tags = {
    Name = "db-subnet-01"
  }
}

resource "aws_subnet" "terraform_private_subnet_2" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "db-subnet-02"
  }
}

# Internet_Gateway
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "reservation-ig"
  }
}

# Nat_Gateway_ElasticIP
resource "aws_eip" "terraform_nat_gip" {
  count  = 1  // 作成するEIPの数
  domain = "vpc"  // VPC内でEIPを使用（vpc = trueの代わりに）
}

# Nat_Gateway
resource "aws_nat_gateway" "terraform_ngw" {
  allocation_id = aws_eip.terraform_nat_gip[0].id // 最初のEIP（Elastic IP）を使用
  subnet_id     = aws_subnet.terraform_public_subnet_2.id // パブリックサブネットを指定する

  tags = {
    Name = "reservation-ng"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.terraform_igw]
}

# ルートテーブル
resource "aws_route_table" "terraform_public_web_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  route {
    cidr_block = "10.0.0.0/21"
    gateway_id = "local"
  }

  tags = {
    Name = "web-routetable"
  }
}

resource "aws_route_table" "terraform_public_elb_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  route {
    cidr_block = "10.0.0.0/21"
    gateway_id = "local"
  }

  tags = {
    Name = "elb-routetable"
  }
}

resource "aws_route_table" "terraform_private_api_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.terraform_ngw.id
}

  route {
    cidr_block = "10.0.0.0/21"
    gateway_id = "local"
  }

  tags = {
    Name = "api-routetable"
  }
}

resource "aws_route_table" "terraform_private_db_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "10.0.0.0/21"
    gateway_id = "local"
  }

  tags = {
    Name = "db-routetable"
  }
}

# ルートテーブルをサブネットに関連付けする
resource "aws_route_table_association" "web_sub_assc" {
  subnet_id      = aws_subnet.terraform_public_subnet_1.id
  route_table_id = aws_route_table.terraform_public_web_routetable.id
}

resource "aws_route_table_association" "elb_sub_assc_1" {
  subnet_id      = aws_subnet.terraform_public_subnet_2.id
  route_table_id = aws_route_table.terraform_public_elb_routetable.id
}

resource "aws_route_table_association" "elb_sub_assc_2" {
  subnet_id      = aws_subnet.terraform_public_subnet_3.id
  route_table_id = aws_route_table.terraform_public_elb_routetable.id
}

resource "aws_route_table_association" "api_sub_assc_1" {
  subnet_id      = aws_subnet.terraform_private_subnet_3.id
  route_table_id = aws_route_table.terraform_private_api_routetable.id
}

resource "aws_route_table_association" "api_sub_assc_2" {
  subnet_id      = aws_subnet.terraform_private_subnet_4.id
  route_table_id = aws_route_table.terraform_private_api_routetable.id
}

resource "aws_route_table_association" "db_sub_assc_1" {
  subnet_id      = aws_subnet.terraform_private_subnet_1.id
  route_table_id = aws_route_table.terraform_private_db_routetable.id
}

resource "aws_route_table_association" "db_sub_assc_2" {
  subnet_id      = aws_subnet.terraform_private_subnet_2.id
  route_table_id = aws_route_table.terraform_private_db_routetable.id
}

# セキュリティ・グループ
resource "aws_security_group" "terraform_ec2_sg" {
  name        = "ec2-sg"
  description = "Allow HTTP and SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "terraform_alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# key-pair
# resource "aws_key_pair" "terraform_my_key_pair" {
#   key_name   = "Naemi_Keypair"
#   public_key = file("/Users/81909/.ssh/Naemi_Keypair.pub") # ローカルに保存しているキーペアのパス

# }

resource "aws_security_group" "terraform_api_sg" {
  name        = "api-sg"
  description = "Only allow alb_sg inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.terraform_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "api-sg"
  }
}
