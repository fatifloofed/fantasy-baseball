application     = "fantasy-baseball"
environment     = "dev"
aws_account_id  = "123456789012"
assume_role_arn = "arn:aws:iam::123456789012:role/replace-with-valid-arn"
aws_region      = "eu-west-1"

vpc_cidr_block = "10.0.0.0/16"

public_subnets = {
  web_1 = { cidr_block = "10.0.1.0/24", az = "eu-west-1a" }
  web_2 = { cidr_block = "10.0.2.0/24", az = "eu-west-1b" }
}

private_app_subnets = {
  app_1 = { cidr_block = "10.0.11.0/24", az = "eu-west-1a" }
  app_2 = { cidr_block = "10.0.12.0/24", az = "eu-west-1b" }
}

private_db_subnets = {
  db_1 = { cidr_block = "10.0.21.0/24", az = "eu-west-1a" }
  db_2 = { cidr_block = "10.0.22.0/24", az = "eu-west-1b" }
}


# Replace with a real ACM certificate ARN for your domain
certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/replace-me"


capacity_providers = ["FARGATE", "FARGATE_SPOT"]
ecs_task_cpu         = 256
ecs_task_memory      = 512
api_desired_count    = 1
worker_desired_count = 1
container_port       = 8080
# always put FARGATE first if using both, as it will be the default


db_instance_class        = "db.t3.medium"
db_name                  = "appdb"
db_engine_version        = "16.2"
db_allocated_storage     = 20
db_max_allocated_storage = 100
db_multi_az              = false

tags_project_id  = "FB-001"
tags_BU          = "Engineering"
tags_IT          = "Platform"
tags_desc        = "3-tier web app"
tags_cost_center = "0000"
