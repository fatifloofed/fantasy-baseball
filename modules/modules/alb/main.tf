
resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  load_balancer_type = "application"

  security_groups    = var.alb_sg_id
  subnets            = var.public_subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs {
    bucket  = var.s3_log_bucket
    prefix  = "alb"
    enabled = true
  }

  tags = { Name = "${var.name_prefix}-alb" }
}

# ---------------------------------------------------------------------------
# Target Group — API containers
# ---------------------------------------------------------------------------
resource "aws_lb_target_group" "api" {
  name        = "${var.name_prefix}-api-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip" # Required for Fargate
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = { Name = "${var.name_prefix}-api-tg" }
}

# ---------------------------------------------------------------------------
# HTTPS Listener (primary)
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# ---------------------------------------------------------------------------
# HTTP Listener — permanent redirect to HTTPS
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
