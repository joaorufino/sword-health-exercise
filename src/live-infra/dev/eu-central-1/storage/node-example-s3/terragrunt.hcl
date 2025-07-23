include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/s3.hcl"
  expose = true
}

locals {
  # Load account and common variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  # Extract commonly used variables
  account_name = local.account_vars.locals.account_name
  account_id   = local.common_vars.locals.account_ids[local.account_name]
  name_prefix  = local.common_vars.locals.name_prefix
  aws_region   = local.region_vars.locals.aws_region
}

terraform {
  source = include.envcommon.locals.base_source_url
}

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

# These inputs get merged with the common inputs from the envcommon s3.hcl
inputs = {
  # Environment-specific configuration
  bucket_name = "${local.common_vars.locals.app_bucket_readwrite_name}-${local.account_name}"
  
  # For dev environment, allow force destroy for easier cleanup
  force_destroy = true
  
  # Lifecycle rules to automatically delete objects after 1 day
  lifecycle_rules = {
    delete_old_objects = {
      enabled         = true
      transitions     = []
      expiration_days = 1  # Delete objects after 1 day
      noncurrent_days = 1  # Delete non-current versions after 1 day (for versioned objects)
    }
  }
  
  # Tags
  tags = merge(
    local.common_vars.locals.default_tags,
    {
      Environment = local.account_name
      Application = "node-example"
      Service     = "s3-storage"
      Region      = local.aws_region
      ManagedBy   = "Terragrunt"
    }
  )
}