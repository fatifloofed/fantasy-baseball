locals {
    name_prefix = "${var.application}-${var.environment}"

    azs = distinct([for s in var.public_subnets : s.az])
}