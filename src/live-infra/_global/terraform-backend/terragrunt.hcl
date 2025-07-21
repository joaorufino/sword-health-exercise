# Terraform backend setup - This should be run first before any other infrastructure
# This creates the S3 bucket and DynamoDB table for storing Terraform state

terraform {
  source = "../../../modules//terraform-backend"
}

# Skip including the root terragrunt.hcl since we're bootstrapping
skip = true

# Include common vars but skip the backend configuration
locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  
  # For bootstrap, we'll create resources in the default region
  aws_region   = local.common_vars.locals.default_region
  name_prefix  = local.common_vars.locals.name_prefix
  
  # Get the account ID from environment variable or prompt
  account_id = get_env("AWS_ACCOUNT_ID", "")
}

# Generate provider for bootstrap
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  
  default_tags {
    tags = {
      Terraform   = "true"
      Purpose     = "terraform-backend"
      Environment = "global"
      Project     = "${local.name_prefix}"
    }
  }
}
EOF
}

# Inputs for the backend module
inputs = {
  name_prefix         = local.name_prefix
  aws_region          = local.aws_region
  
  # S3 bucket configuration
  state_bucket_prefix = local.common_vars.locals.state_bucket_prefix
  enable_versioning   = true
  
  # DynamoDB configuration
  dynamodb_table_name = local.common_vars.locals.dynamodb_table_name
  
  # Additional S3 bucket for access logging
  create_access_logging_bucket = true
}