locals {
    public_subnets_by_az = { for k,v in var.public_subnets : v.az => k }

    private_subnets_by_tier = {
        app = { for k,v in var.private_subnets : k => v if v.tier == "app" }
        db = { for k,v in var.private_subnets : k => v if v.tier == "db" }
    }
}