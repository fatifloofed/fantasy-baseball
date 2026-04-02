output "vpc_id" {
    value = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
    value = [for s in aws_subnet.public_subnets : s.id]
}

output "app_subnet_ids" {
    value = [for s in aws_subnet.private_app : s.id]
}

output "db_subnet_ids" {
    value = [for s in aws_subnet.private_db : s.id]
}

output "private_route_table_ids" {
    value = concat([for rt in aws_route_table.app_rt : rt.id], [aws_route_table.db_rt.id])
}