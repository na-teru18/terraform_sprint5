# ECSクラスタ
resource "aws_ecs_cluster" "terraform_ecs_cluster" {
  name = "reservation-ecs-cluster"
}

# ECSクラスタの容量プロバイダー
resource "aws_ecs_cluster_capacity_providers" "terraform_ecs_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.terraform_ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ECSタスク
resource "aws_ecs_task_definition" "terraform_ecs_task" {
  family                   = "cloudtech-reservation-api-task" # タスク定義ファミリー名
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 0.5 GB　※1GB = 1024 MiB/GB

  # タスクロールを関連付ける
  task_role_arn            = aws_iam_role.terraform_ecs_task_role.arn
  # タスク実行ロールを関連付ける
  execution_role_arn       = aws_iam_role.terraform_ecs_execution_role.arn
  depends_on = [
    aws_db_instance.terraform_db 
  ]

  container_definitions = jsonencode([ # コンテナ定義
    {
      name      = "reservation-container"
      image     = "public.ecr.aws/z7i1h7x3/cloudtech-reservation-api:latest" # 使用するイメージのURI
      # cpu       = 256 ※今回コンテナが1つしかないため不要
      # memory    = 512 ※今回コンテナが1つしかないため不要
      essential = true
      # protocol    = "HTTP" # アプリケーションプロトコルはターゲットグループ内で定義する
      portMappings = [ # コンテナポート, プロトコル, アプリケーションプロトコル
        {
          containerPort = 80 # 各種アプリケーションからのトラフィックを待ち受けているポート番号
          hostPort      = 80 # 外部からのトラフィックを受け付けるポート番号
          protocol      = "tcp" # レイヤー4(TCP or UDP)を指定できる
        }
      ]
      environment = [ # 環境変数の設定
      {"name": "API_PORT", "value": "80"},
      {"name": "DB_USERNAME", "value": aws_db_instance.terraform_db.username},
      {"name": "DB_PASSWORD", "value": aws_db_instance.terraform_db.password},
      {"name": "DB_SERVERNAME", "value": aws_db_instance.terraform_db.address},
      {"name": "DB_PORT", "value": tostring(aws_db_instance.terraform_db.port)},
      {"name": "DB_NAME", "value": aws_db_instance.terraform_db.db_name}
      ],
    }
  ])

runtime_platform { # OSの設定
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
}
}

# ECSサービス
resource "aws_ecs_service" "terraform_ecs_service" {
  name            = "reservation-service"
  cluster         = aws_ecs_cluster.terraform_ecs_cluster.id
  task_definition = aws_ecs_task_definition.terraform_ecs_task.arn
  desired_count   = 2 # 常に実行しておきたいタスク数
  launch_type     = "FARGATE" # 実行環境

  load_balancer {
    target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
    container_name   = "reservation-container"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.terraform_private_subnet_3.id, aws_subnet.terraform_private_subnet_4.id]
    security_groups  = [aws_security_group.terraform_api_sg.id]
    assign_public_ip = false
  }

  scheduling_strategy = "REPLICA"
}

# ECSサービスのオートスケーリング機能
resource "aws_appautoscaling_target" "terraform_ecs_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.terraform_ecs_cluster.name}/${aws_ecs_service.terraform_ecs_service.name}" # 対象のリソースID ECSサービスの場合、service/クラスター名/サービス名
  scalable_dimension = "ecs:service:DesiredCount" # ECSサービスの希望タスク数を増減させる
  service_namespace  = "ecs" # オートスケーリングの対象となるAWSサービス
}

# スケーリングポリシー
resource "aws_appautoscaling_policy" "terraform_ecs_policy" {
  name               = "api-auto-scaling-policy"
  policy_type        = "TargetTrackingScaling" # ターゲット追跡のスケーリングポリシー
  # ECSスケーリングポリシーにどのECSターゲットが適用されるか紐づける
  resource_id        = aws_appautoscaling_target.terraform_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.terraform_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.terraform_ecs_target.service_namespace

  # ターゲット追跡スケーリングポリシー
  target_tracking_scaling_policy_configuration {
    # サービスメトリクス(ECS)
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value     = 90
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    disable_scale_in = false
  }
}