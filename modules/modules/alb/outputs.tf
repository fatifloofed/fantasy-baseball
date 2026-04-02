output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "api_target_group_arn" {
  value = aws_lb_target_group.api.arn
}
