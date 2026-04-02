
resource "aws_security_group" "alb_sg" {
    name = "${var.name_prefix}-alb-sg"
    vpc_id = var.vpc_id

    lifecycle {
        create_before_destroy = true
    }

    tags = {
        Name = "${var.name_prefix}-alb-sg"
    }
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
    from_port = var.container_port
    to_port = var.container_port
    referenced_security_group_id= aws_security_group.app_sg.id
}

resource "aws_security_group" "app_sg" {
    name = "app_sg"
    description = "Security group for app tier"
    vpc_id = var.vpc_id

    lifecycle {
        create_before_destroy = true
    }
    tags = {
        Name = "${var.name_prefix}-app-sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb" {
    security_group_id = aws_security_group.app_sg.id
    ip_protocol = "tcp"
    from_port = 8080
    to_port = 8080
    referenced_security_group_id= aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "allow_https_outbound" {
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
    name = "${var.name_prefix}-db-sg"
    vpc_id = var.vpc_id
    tags = {
        Name = "${var.name_prefix}-db-sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_app" {
    security_group_id = aws_security_group.db_sg.id
    ip_protocol = "tcp"
    from_port = 5432
    to_port = 5432
    referenced_security_group_id= aws_security_group.app_sg.id
}

resource "aws_security_group" "endpoint_sg" {
  name        = "${var.name_prefix}-endpoint-sg"
  description = "VPC Interface Endpoints: accept HTTPS from within VPC."
  vpc_id      = var.vpc_id

  lifecycle { 
    create_before_destroy = true 
    }

  tags = { 
    Name = "${var.name_prefix}-endpoint-sg" 
    }
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_https" {
  security_group_id            = aws_security_group.endpoint_sg.id
  description                  = "HTTPS from app tier"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.app_sg.id
}
