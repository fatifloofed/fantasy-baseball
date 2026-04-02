output "ecs_log_group_name" {
  description = "Base name for ECS CloudWatch log groups"
  value       = "/ecs/${var.name_prefix}"
}