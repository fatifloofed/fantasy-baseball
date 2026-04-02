#VPC

resource "aws_vpc" "main_vpc" {
    cidr_block = var.vpc_cidr_block

    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "${var.name_prefix}-vpc"
    }
}

# IGW for public subnets

resource "aws_internet_gateway" "main_igw" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
        Name = "${var.name_prefix}-igw"
    }
}

# Subnets

resource "aws_subnet" "public_subnets" {
    for_each = var.public_subnets

    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value.cidr_block
    availability_zone = each.value.az

    tags = {
        Name = "${var.name_prefix}-web_subnet-${each.key}"
        Tier = "web"
    }
}

resource "aws_subnet" "private_app" {
    for_each = var.private_app_subnets

    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value.cidr_block
    availability_zone = each.value.az

    tags = {
        Name = "${var.name_prefix}-app_subnet-${each.key}"
        Tier = "app"
    }
}

resource "aws_subnet" "private_db" {
    for_each = var.private_db_subnets

    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value.cidr_block
    availability_zone = each.value.az

    tags = {
        Name = "${var.name_prefix}-db_subnet-${each.key}"
        Tier = "db"
    }
}

# EIPs for NAT Gateways (1 per AZ)

resource "aws_eip" "nat_eip" {
    for_each = aws_subnet.public_subnets
    domain = "vpc"
    tags = {
        Name = "${var.name_prefix}-nat_eip-${each.key}"
    }
}

resource "aws_nat_gateway" "nat_gw" {
    for_each = aws_subnet.public_subnets

    allocation_id = aws_eip.nat_eip[each.key].id
    subnet_id = each.value.id

    tags = {
        Name = "${var.name_prefix}-nat_gw-${each.key}"
    } 
}

# Route tables

resource  "aws_route_table" "web_rt" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_igw.id
    }
    tags = {
        Name = "${var.name_prefix}-web_rt"
    }
}

resource "aws_route_table_association" "web_rt_assoc" {
    for_each = aws_subnet.public_subnets

    subnet_id = each.value.id
    route_table_id = aws_route_table.web_rt.id
}


resource  "aws_route_table" "app_rt" {
    for_each = aws_subnet.public_subnets
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw[each.key].id
    }
    tags = {
        Name = "${var.name_prefix}-app_rt-${each.key}"
    }
}

resource "aws_route_table_association" "app_rt_assoc" {
    for_each = aws_subnet.private_app

    subnet_id = each.value.id
    route_table_id = aws_route_table.app_rt[local.app_subnet_nat_key[each.key]].id
}

resource  "aws_route_table" "db_rt" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "${var.name_prefix}-db_rt"
    }
}

resource "aws_route_table_association" "db_rt_assoc" {
    for_each = aws_subnet.private_db

    subnet_id = each.value.id
    route_table_id = aws_route_table.db_rt.id
}

#NACL

# --- Web tier NACL ---
resource "aws_network_acl" "web" {
  vpc_id     = aws_vpc.main_vpc.id
  subnet_ids = [for s in aws_subnet.public_subnets : s.id]

  # Inbound: allow HTTPS (443) and HTTP (80) from anywhere
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  # Ephemeral ports for return traffic
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound: allow all (SGs handle specifics)
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = { Name = "${var.name_prefix}-nacl-web" }
}

# --- App tier NACL ---
resource "aws_network_acl" "app" {
  vpc_id     = aws_vpc.main_vpc.id
  subnet_ids = [for s in aws_subnet.private_app : s.id]

  # Inbound from VPC only (ALB → app container port, DB return traffic, etc.)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 65535
  }

  # Outbound to VPC and internet (NAT egress for ECR pull, external APIs)
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = { Name = "${var.name_prefix}-nacl-app" }
}

# --- DB tier NACL ---
resource "aws_network_acl" "db" {
  vpc_id     = aws_vpc.main_vpc.id
  subnet_ids = [for s in aws_subnet.private_db : s.id]

  # Inbound: only PostgreSQL from within the VPC
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 5432
    to_port    = 5432
  }
  # Return traffic for outbound connections (e.g. RDS Enhanced Monitoring)
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound: only within VPC
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 65535
  }

  tags = { Name = "${var.name_prefix}-nacl-db" }
}

