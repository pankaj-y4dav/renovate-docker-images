resource "aws_ecs_task_definition" "datadog_agent" {
  family                   = "datadog-agent"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "datadog-agent"
      image     = "public.ecr.aws/datadog/agent:7.76.2"
      essential = true

      environment = [
        {
          name  = "DD_API_KEY"
          value = var.datadog_api_key
        },
        {
          name  = "DD_SITE"
          value = "datadoghq.com"
        },
        {
          name  = "ECS_FARGATE"
          value = "true"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/datadog-agent"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "fluent_bit" {
  family                   = "fluent-bit"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "fluent-bit"
      image     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:2.31.12"
      essential = true

      environment = [
        {
          name  = "AWS_REGION"
          value = "us-east-1"
        }
      ]

      firelensConfiguration = {
        type = "fluentbit"
      }
    }
  ])
}
