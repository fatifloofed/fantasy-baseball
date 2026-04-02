resource "aws_vpc" "main_vpc" {
    cidr_block = var.vpc_cidr_block
# add necessary tags later FOR ALL RESOURCES
    enable_dns_support = true
    enable_dns_hostnames = true
}

#optimize later

resource "aws_subnet" "private_subnets" {
    for_each = var.private_subnets

    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value.cidr_block
    availability_zone = each.value.az
}

resource "aws_subnet" "public_subnets" {
    for_each = var.public_subnets

    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value.cidr_block
    availability_zone = each.value.az
}


resource "aws_internet_gateway" "main_igw" {
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_eip" "nat_eip" {
    for_each = local.public_subnets_by_az
    domain = "vpc"
}

# fix nat_gateway association later, currently creates one nat gateway per public subnet, which is not ideal but works for now. Optimize later.
resource "aws_nat_gateway" "nat_gw" {
    for_each = local.public_subnets_by_az

    allocation_id = aws_eip.nat_eip[each.key].id
    subnet_id = aws_subnet.public_subnets[each.value].id
}

# resource "aws_nat_gateway_association" "nat_gw_assoc" {
#     for_each = aws_subnet.public_subnets

#     subnet_id = aws_subnet.public_subnets[each.key].id
#     nat_gateway_id = aws_nat_gateway.nat_gw[each.key].id
# }

resource  "aws_route_table" "web_rt" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_igw.id
    }
}

resource "aws_route_table_association" "web_rt_assoc" {
    for_each = aws_subnet.public_subnets

    subnet_id = each.value.id
    route_table_id = aws_route_table.web_rt.id
}

# 1 route table per AZ
resource  "aws_route_table" "app_rt" {
    for_each = aws_nat_gateway.nat_gw
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = each.value.id
    }
}

resource "aws_route_table_association" "app_rt_assoc" {
    for_each = local.private_subnets_by_tier.app

    subnet_id = aws_subnet.private_subnets[each.key].id
    route_table_id = aws_route_table.app_rt[each.value.az].id
}

resource  "aws_route_table" "db_rt" {
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table_association" "db_rt_assoc" {
    for_each = local.private_subnets_by_tier.db

    subnet_id = aws_subnet.private_subnets[each.key].id
    route_table_id = aws_route_table.db_rt.id
}

#THINK ABOUT REMOVING NACL RESOURCES (DENY ALL IF NO RULES ARE CREATED)
resource "aws_network_acl" "nacl" {
    for_each = {
        web = "web"
        app = "app"
        db = "db"
    }

    vpc_id = aws_vpc.main_vpc.id

}


resource "aws_network_acl_association" "web_nacl_assoc" {
    for_each = aws_subnet.public_subnets

    subnet_id = each.value.id
    network_acl_id = aws_network_acl.nacl["web"].id
}

resource "aws_network_acl_association" "app_nacl_assoc" {
    for_each = local.private_subnets_by_tier.app

    subnet_id = aws_subnet.private_subnets[each.key].id
    network_acl_id = aws_network_acl.nacl["app"].id
}

resource "aws_network_acl_association" "db_nacl_assoc" {
    for_each = local.private_subnets_by_tier.db

    subnet_id = aws_subnet.private_subnets[each.key].id
    network_acl_id = aws_network_acl.nacl["db"].id
}



resource "aws_security_group" "alb_sg" {
    name = "alb_sg"
    description = "Security group for ALB (web tier)"
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_http" {
    security_group_id = aws_security_group.alb_sg.id
    ip_protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_https" {
    security_group_id = aws_security_group.alb_sg.id
    ip_protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_app" {
    security_group_id = aws_security_group.alb_sg.id
    ip_protocol = "tcp"
    from_port = 8080
    to_port = 8080
    referenced_security_group_id= aws_security_group.app_sg.id
}

resource "aws_security_group" "app_sg" {
    name = "app_sg"
    description = "Security group for app tier"
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb" {
    security_group_id = aws_security_group.app_sg.id
    ip_protocol = "tcp"
    from_port = 8080
    to_port = 8080
    referenced_security_group_id= aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
    security_group_id = aws_security_group.app_sg.id
    ip_protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "egress_db" {
    security_group_id = aws_security_group.app_sg.id
    ip_protocol = "tcp"
    from_port = 5432
    to_port = 5432
    referenced_security_group_id= aws_security_group.db_sg.id
}

resource "aws_security_group" "db_sg" {
    name = "db_sg"
    description = "Security group for db tier"
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_app" {
    security_group_id = aws_security_group.db_sg.id
    ip_protocol = "tcp"
    from_port = 5432
    to_port = 5432
    referenced_security_group_id= aws_security_group.app_sg.id
}