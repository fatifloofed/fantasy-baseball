

module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  vpc_cidr_block      = var.vpc_cidr_block
  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_db_subnets  = var.private_db_subnets
}

module "security" {
  source = "./modules/security"

  name_prefix    = local.name_prefix
  vpc_id         = module.network.vpc_id
  container_port = var.container_port
}

module "kms" {
  source = "./modules/kms"

  name_prefix    = local.name_prefix
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
}

module "secrets" {
  source = "./modules/secrets"

  name_prefix = local.name_prefix
  kms_key_arn = module.kms.secrets_key_arn
}


module "iam" {
  source = "./modules/iam"

  name_prefix    = local.name_prefix
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  kms_key_arn    = module.kms.secrets_key_arn
}

module "alb" {
  source = "./modules/alb"

  name_prefix     = local.name_prefix
  public_subnets  = module.network.public_subnet_ids
  alb_sg_id       = module.security.alb_sg_id
  vpc_id          = module.network.vpc_id
  certificate_arn = var.certificate_arn
  s3_log_bucket   = module.s3.alb_logs_bucket_id
  container_port = var.container_port
}

module "cloudfront" {
  source = "./modules/cloudfront"

  name_prefix               = local.name_prefix
  s3_bucket_regional_domain = module.s3.web_assets_bucket_regional_domain
  s3_log_bucket_domain      = module.s3.alb_logs_bucket_domain  
  price_class               = "PriceClass_100"

  # Optional — uncomment for a custom domain:
  # domain_aliases      = ["app.example.com"]
  # acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
  #   ^^ Note: CloudFront ACM certs MUST be in us-east-1, even if your stack is eu-west-1
}

module "s3" {
  source = "./modules/s3"

  name_prefix                 = local.name_prefix
  aws_account_id              = var.aws_account_id
  kms_key_arn                 = module.kms.services_key_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn  
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix = local.name_prefix
  kms_key_arn = module.kms.services_key_arn
}

module "ecs" {
  source = "./modules/ecs"

  name_prefix          = local.name_prefix
  aws_region           = var.aws_region
  aws_account_id       = var.aws_account_id
  private_app_subnets  = module.network.app_subnet_ids
  app_sg_id            = module.security.app_sg_id
  execution_role_arn   = module.iam.ecs_execution_role_arn
  task_role_arn        = module.iam.ecs_task_role_arn
  alb_target_group_arn = module.alb.api_target_group_arn
  kms_key_arn          = module.kms.services_key_arn
  log_group_name       = module.monitoring.ecs_log_group_name
  ecr_api_repo_url     = module.ecr.api_repo_url
  ecr_worker_repo_url  = module.ecr.worker_repo_url
  ecr_sched_repo_url   = module.ecr.scheduled_task_repo_url
  db_secret_arn        = module.secrets.db_secret_arn
  app_secret_arn       = module.secrets.app_secret_arn
  ecs_task_cpu         = var.ecs_task_cpu
  ecs_task_memory      = var.ecs_task_memory
  api_desired_count    = var.api_desired_count
  worker_desired_count = var.worker_desired_count
  container_port       = var.container_port
  capacity_providers   = var.capacity_providers
}

module "rds" {
  source = "./modules/rds"

  name_prefix              = local.name_prefix
  db_subnet_ids            = module.network.db_subnet_ids
  db_sg_id                 = module.security.db_sg_id
  kms_key_arn              = module.kms.services_key_arn
  db_secret_arn            = module.secrets.db_secret_arn
  db_name                  = var.db_name
  db_instance_class        = var.db_instance_class
  db_engine_version        = var.db_engine_version
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_multi_az              = var.db_multi_az
}

module "endpoints" {
  source = "./modules/endpoints"

  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  aws_region          = var.aws_region
  app_subnet_ids      = module.network.app_subnet_ids
  route_table_ids = module.network.private_route_table_ids
  endpoint_sg_id      = module.security.endpoint_sg_id
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix    = local.name_prefix
  kms_key_arn    = module.kms.cloudwatch_key_arn
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
}
