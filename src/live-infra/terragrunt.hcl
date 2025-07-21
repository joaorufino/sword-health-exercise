# Root terragrunt configuration
# This file is included by all terragrunt configurations in the live-infra directory

# Load common variables
locals {
  # Load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  
  # Load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  
  # Load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  # Extract commonly used variables
  name_prefix    = local.common_vars.locals.name_prefix
  account_ids    = local.common_vars.locals.account_ids
  account_name   = local.account_vars.locals.account_name
  account_id     = local.account_ids[local.account_name]
  aws_region     = local.region_vars.locals.aws_region
  
  # S3 backend configuration
  state_bucket   = "${local.common_vars.locals.state_bucket_prefix}-${local.account_id}"
  dynamodb_table = "${local.common_vars.locals.dynamodb_table_name}-${local.account_name}"
  
  # Load override tags if they exist
  override_tags        = try(yamldecode(file("${get_terragrunt_dir()}/tags.yml")), {})
  parent_override_tags = try(yamldecode(file(find_in_parent_folders("tags.yml"))), {})
  
  # Merge tags: default -> parent overrides -> local overrides
  tags = merge(
    local.common_vars.locals.default_tags,
    local.parent_override_tags,
    local.override_tags,
    {
      Environment = local.account_name
      Region      = local.aws_region
    }
  )
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  
  # Only these AWS Account IDs may be operated on
  allowed_account_ids = ["${local.account_id}"]
  
  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}

# Additional provider for us-east-1 (required for some resources like CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  allowed_account_ids = ["${local.account_id}"]
  
  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}
EOF
}

# Generate provider version constraints
generate "provider_version" {
  path      = "provider_version_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}
EOF
}

# Configure remote state
remote_state {
  backend = "s3"
  
  config = {
    encrypt        = true
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = local.dynamodb_table
    
    # Enable bucket versioning and access logging
    skip_bucket_versioning         = false
    skip_bucket_public_access_blocking = false
    skip_bucket_root_access        = false
    
    # Server-side encryption
    bucket_sse_algorithm = "AES256"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Default inputs available to all configurations
inputs = {
  aws_account_id = local.account_id
  aws_region     = local.aws_region
  account_name   = local.account_name
  name_prefix    = local.name_prefix
  
  # Pass common configurations
  vpc_cidr     = local.common_vars.locals.vpc_cidrs[local.account_name]
  azs_count    = local.common_vars.locals.azs_count
  
  # Tags
  tags = local.tags
}

# Terraform configuration
terraform {
  # Allow .terraform-version file to be included
  include_in_copy = [".terraform-version"]
  
  # Retry lock for up to 10 minutes
  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=10m"]
  }
  
  # Auto-approve for dev environment (be careful!)
  extra_arguments "auto_approve" {
    commands = ["apply", "destroy"]
    arguments = concat(
      local.account_name == "dev" ? ["-auto-approve"] : [],
      []
    )
  }
}

# Hooks for validation
terraform {
  before_hook "before_hook" {
    commands = ["apply", "plan"]
    execute  = ["terraform", "fmt", "-check"]
  }
  
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["echo", "Terraform apply completed successfully!"]
    run_on_error = false
  }
}

# Retry configuration
retry_configuration {
  retry_attempts       = 3
  retry_delay_seconds  = 5
  retryable_exit_codes = [1]
}