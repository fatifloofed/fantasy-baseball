resource "aws_vpc_endpoint" "s3" {
    vpc_id = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.s3"
    vpc_endpoint_type = "Gateway"
    route_table_ids = var.route_table_ids

    tags = {
        Name = "${var.name_prefix}-s3-endpoint"
    }
}

resource "aws_vpc_endpoint" "interface" {
    for_each = local.interface_endpoints

    vpc_id = var.vpc_id
    vpc_endpoint_type = "Interface"
    service_name = each.value
    security_group_ids = [var.endpoint_sg_id]
    subnet_ids = var.app_subnet_ids
    private_dns_enabled = true
    tags = {
        Name = "${var.name_prefix}-${each.key}-endpoint"
    }
}