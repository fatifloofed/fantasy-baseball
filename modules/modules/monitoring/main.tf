resource "aws_cloudwatch_log_group" "ecs" {
  for_each = toset(local.ecs_services)

  name              = "/ecs/${var.name_prefix}/${each.key}"
  retention_in_days = 30
  kms_key_id        = var.kms_key_arn

  tags = { Name = "${var.name_prefix}-lg-${each.key}" }
}