output "api_repo_url" {
  value = aws_ecr_repository.service["api"].repository_url
}

output "worker_repo_url" {
  value = aws_ecr_repository.service["worker"].repository_url
}

output "scheduled_task_repo_url" {
  value = aws_ecr_repository.service["scheduled-task"].repository_url
}