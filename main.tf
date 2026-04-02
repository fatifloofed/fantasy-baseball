# The main.tf file typically serves as the primary entry point for a Terraform configuration.
# This is where the module is called, linking the input variables to the module's parameters.

# module "app_data_storage" {
#   # INSTRUCTION: Replace this with the actual source and version of the S3 module
#   source  = "PRA2redcedar.gitlab.rcbc.ygc.inet:5050/infrastructure-modules/s3.git?ref=v3.0.0"
#   
#   # Module Inputs
#   name          = "${var.environment}-app-data-${var.bucket_suffix}"
#   environment   = var.environment
#   region        = var.aws_region
#   acl           = var.acl_setting
#   versioning_on = var.versioning_enabled
#   
#   # Tags common to all environments
#   tags = {
#     Project     = "AppStack"
#     ManagedBy   = "Terraform"
#     Environment = var.environment
#   }
# }