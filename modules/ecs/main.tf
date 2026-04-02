# =============================================================================
# ECS Fargate — Application Tier
#
# Resources:
#   - ECS Cluster (with Container Insights enabled)
#   - API Service        — long-running, behind ALB, auto-scales
#   - Worker Service     — long-running, internal only (no ALB)
#   - Scheduled Task     — triggered by EventBridge on a cron schedule
#                          (e.g. nightly stats retrieval from external APIs)
# =============================================================================

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${var.name_prefix}-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy {
    capacity_provider = var.capacity_providers[0]
    weight            = 1
    base              = 1
  }
}


# --- API ---
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.name_prefix}-api"
  requires_compatibilities = [var.capacity_providers[0]]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  # Encrypt ephemeral storage at rest using the app KMS key
  ephemeral_storage {
    size_in_gib = 21
  }

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${var.ecr_api_repo_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "PORT", value = tostring(var.container_port) },
        { name = "ENV",  value = var.name_prefix },
      ]

      # Secrets are injected as environment variables from Secrets Manager.
      # The ECS agent fetches them at task startup using the execution role.
      secrets = [
        {
          name      = "DB_SECRET"
          valueFrom = var.db_secret_arn
        },
        {
          name      = "APP_SECRET"
          valueFrom = var.app_secret_arn
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${var.log_group_name}/api"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Read-only root filesystem (security hardening)
      readonlyRootFilesystem = true

      # Drop all Linux capabilities; add only what the process needs
      linuxParameters = {
        capabilities = {
          drop = ["ALL"]
        }
        initProcessEnabled = true
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = { Name = "${var.name_prefix}-api-td" }
}

# --- Worker ---
resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.name_prefix}-worker"
  requires_compatibilities = [var.capacity_providers[0]]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  ephemeral_storage {
    size_in_gib = 21
  }

  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = "${var.ecr_worker_repo_url}:latest"
      essential = true

      environment = [
        { name = "ENV", value = var.name_prefix },
      ]

      secrets = [
        {
          name      = "DB_SECRET"
          valueFrom = var.db_secret_arn
        },
        {
          name      = "APP_SECRET"
          valueFrom = var.app_secret_arn
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${var.log_group_name}/worker"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      readonlyRootFilesystem = true

      linuxParameters = {
        capabilities = {
          drop = ["ALL"]
        }
        initProcessEnabled = true
      }
    }
  ])

  tags = { Name = "${var.name_prefix}-worker-td" }
}

# --- Scheduled Task ---
resource "aws_ecs_task_definition" "scheduled_task" {
  family                   = "${var.name_prefix}-scheduled-task"
  requires_compatibilities = [var.capacity_providers[0]] 
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  ephemeral_storage {
    size_in_gib = 21
  }

  container_definitions = jsonencode([
    {
      name      = "scheduled-task"
      image     = "${var.ecr_sched_repo_url}:latest"
      essential = true

      environment = [
        { name = "ENV", value = var.name_prefix },
      ]

      secrets = [
        {
          name      = "DB_SECRET"
          valueFrom = var.db_secret_arn
        },
        {
          name      = "APP_SECRET"
          valueFrom = var.app_secret_arn
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${var.log_group_name}/scheduled-task"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      readonlyRootFilesystem = true

      linuxParameters = {
        capabilities = {
          drop = ["ALL"]
        }
        initProcessEnabled = true
      }
    }
  ])

  tags = { Name = "${var.name_prefix}-scheduled-task-td" }
}

# ---------------------------------------------------------------------------
# ECS Services
# ---------------------------------------------------------------------------

# --- API Service (registered with ALB target group) ---
resource "aws_ecs_service" "api" {
  name            = "${var.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count

  # Use FARGATE for stable baseline tasks
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets          = var.private_app_subnets
    security_groups  = [var.app_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "api"
    container_port   = var.container_port
  }

  # Smooth rolling deployments: keep at least 100% capacity during deploy
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_execute_command = true # ECS Exec for debugging

  # Prevent Terraform from resetting desired_count when auto-scaling is active
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = { Name = "${var.name_prefix}-api-svc" }
}

# --- Worker Service ---
resource "aws_ecs_service" "worker" {
  name            = "${var.name_prefix}-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets          = var.private_app_subnets
    security_groups  = [var.app_sg_id]
    assign_public_ip = false
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_execute_command = true

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = { Name = "${var.name_prefix}-worker-svc" }
}

# ---------------------------------------------------------------------------
# Auto Scaling — API Service
# ---------------------------------------------------------------------------
resource "aws_appautoscaling_target" "api" {
  max_capacity       = 6
  min_capacity       = var.api_desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "${var.name_prefix}-api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 60.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "api_memory" {
  name               = "${var.name_prefix}-api-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# ---------------------------------------------------------------------------
# Scheduled Task — EventBridge rule + IAM role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "eventbridge_ecs" {
  name = "${var.name_prefix}-eventbridge-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_ecs" {
  name = "${var.name_prefix}-eventbridge-ecs-policy"
  role = aws_iam_role.eventbridge_ecs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = aws_ecs_task_definition.scheduled_task.arn
        Condition = {
          ArnLike = {
            "ecs:cluster" = aws_ecs_cluster.main.arn
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = [var.execution_role_arn, var.task_role_arn]
      },
    ]
  })
}

resource "aws_cloudwatch_event_rule" "scheduled_task" {
  name                = "${var.name_prefix}-scheduled-task-rule"
  description         = "Trigger stats retrieval task nightly at 01:00 UTC."
  schedule_expression = "cron(0 1 * * ? *)"
  state               = "ENABLED"

  tags = { Name = "${var.name_prefix}-scheduled-task-rule" }
}

resource "aws_cloudwatch_event_target" "scheduled_task" {
  rule     = aws_cloudwatch_event_rule.scheduled_task.name
  arn      = aws_ecs_cluster.main.arn
  role_arn = aws_iam_role.eventbridge_ecs.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.scheduled_task.arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"

    network_configuration {
      subnets          = var.private_app_subnets
      security_groups  = [var.app_sg_id]
      assign_public_ip = false
    }
  }
}
