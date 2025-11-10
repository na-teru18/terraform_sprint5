locals {
  sub_domain = "api.cloud-tech-teruya-hands-on.com" # 使用するサブ・ドメイン
}

# ACM（AWS Certificate Manager）で事前に発行したSSL/TLS証明書の情報
data "aws_acm_certificate" "terraform_sub_domain" {
  region   = "us-east-1"
  domain   = local.sub_domain
  statuses = ["ISSUED"]
}

# ALB
resource "aws_lb" "terraform_alb" {
  name               = "api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terraform_alb_sg.id]
  subnets            = [aws_subnet.terraform_public_subnet_2.id, aws_subnet.terraform_public_subnet_3.id]
  ip_address_type    = "ipv4"

  tags = {
    Environment = "api-alb"
  }
}

# # ターゲット・グループのバックエンドサーバ
# locals {
#   api_server_ids = {
#     "api-ser-1" = aws_instance.terraform_api_server_1.id, "api-ser-2" = aws_instance.terraform_api_server_2.id
#   }
# }

# ターゲット・グループ
resource "aws_lb_target_group" "terraform_alb_target_group" {
  name     = "api-target-group"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.terraform_vpc.id
  health_check {
    interval            = 10
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 6
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

# # バックエンド・サーバをターゲット・グループとして登録する
# resource "aws_lb_target_group_attachment" "terraform_target_group_attachment" {
#   for_each         = local.api_server_ids
#   target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
#   target_id        = each.value
#   port             = 80
# }

# リスナー
resource "aws_lb_listener" "terraform_alb_listener" {
  load_balancer_arn = aws_lb.terraform_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = data.aws_acm_certificate.terraform_sub_domain.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
  }
}

# リスナー・ルール
resource "aws_lb_listener_rule" "myapp_listener_rule" {
  listener_arn = aws_lb_listener.terraform_alb_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# # 起動テンプレートの作成
# resource "aws_launch_template" "terraform_launch_template" {
#   name          = "api-server-template"
#   image_id      = "ami-080887fe54897f457" # AMIのIDを指定
#   instance_type = "t2.micro"
#   network_interfaces {
#     associate_public_ip_address = true
#     security_groups             = [aws_security_group.terraform_api_sg.id]
#   }

#   user_data = <<-EOF
# #!/bin/bash
# HOME_DIR="/home/ec2-user/"

# dnf update -y
# dnf install -y git golang nginx

# cd ${HOME_DIR}
# git clone https://github.com/CloudTechOrg/cloudtech-reservation-api.git

# cat << 'SERVICE_FILE' > /etc/systemd/system/goserver.service
# [Unit]
# Description=Go Server

# [Service]
# WorkingDirectory=/home/ec2-user/cloudtech-reservation-api
# ExecStart=/usr/bin/go run main.go
# User=ec2-user
# Restart=always

# [Install]
# WantedBy=multi-user.target
# SERVICE_FILE

# systemctl daemon-reload
# systemctl enable goserver.service
# systemctl start goserver.service

# systemctl start nginx
# systemctl enable nginx

# sed -i '/^server {/, /^}$/d' /etc/nginx/nginx.conf

# cat << 'NGINX_CONF' >> /etc/nginx/nginx.conf
# server {
#         listen 80;
#         server_name _;
#         location / {
#             proxy_pass http://localhost:8080;
#             proxy_http_version 1.1;
#             proxy_set_header Upgrade $http_upgrade;
#             proxy_set_header Connection 'upgrade';
#             proxy_set_header Host $host;
#             proxy_cache_bypass $http_upgrade;
#         }
# }

# systemctl restart nginx
#   EOF
# }

# Auto Scaling Group
# resource "aws_autoscaling_group" "terraform_auto_scaling_group" {
#   name                      = "api-autoscaling"
#   max_size                  = 4 # 最大キャパシティ
#   min_size                  = 2 # 最小キャパシティ
#   desired_capacity          = 2 # 希望するキャパシティ
#   health_check_grace_period = 300
#   health_check_type         = "EC2"
#   launch_template {
#     id      = aws_launch_template.terraform_launch_template.id
#     version = "$Latest"
#   }
#   vpc_zone_identifier = [aws_subnet.terraform_private_subnet_3.id, aws_subnet.terraform_private_subnet_4.id]
#   target_group_arns   = [aws_lb_target_group.terraform_alb_target_group.arn]
# }

# Autoscaling Policy
# resource "aws_autoscaling_policy" "terraform_asg_policy" {
#   name                   = "api-asg-policy"
#   autoscaling_group_name = aws_autoscaling_group.terraform_auto_scaling_group.name
#   policy_type            = "TargetTrackingScaling"

#   target_tracking_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#     target_value = 70.0
#   }
# }
