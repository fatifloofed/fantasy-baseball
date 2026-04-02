vpc_cidr_block = "10.0.0.0//16"
private_subnets = {
    app_1 = {cidr_block = "10.0.11.0/24", az= "eu-west-1a", tier="app"}
    app_2 = {cidr_block = "10.0.12.0/24", az= "eu-west-1b", tier="app"}
    db_1 = {cidr_block = "10.0.21.0/24", az= "eu-west-1a", tier="db"}
    db_2 = {cidr_block = "10.0.22.0/24", az= "eu-west-1b", tier="db"}
}

public_subnets = {
    web_1 = {cidr_block = "10.0.1.0/24", az= "eu-west-1a", tier="web"}
    web_2 = {cidr_block = "10.0.2.0/24", az= "eu-west-1b", tier="web"}
}

eips = ["eipalloc-az1", "eipalloc-az2"]
# application     = "casab"
# environment     = "dev"
# aws_account_id  = "123456789012"
# assume_role_arn = "arn:aws:iam::123456789012:role/replace-with-valid-arn"


# tags_project_id  = "AddProjectID"
# tags_BU          = "AddBU"
# tags_IT          = "AddDivision"
# tags_desc        = "AddDescription"
# tags_cost_center = "0000"
# tags_tier        = "0"
# tags_automation  = false
# tags_sched       = false