include "root" {
  path = find_in_parent_folders("root.hcl")
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
  source = "${get_repo_root()}/src/infra-modules/messaging/sqs"
}

# Input variables
inputs = {
  queue_name = "${local.common_vars.locals.sqs_queue_name}-${local.account_name}"
  
  # DLQ configuration from common.hcl
  enable_dlq        = local.common_vars.locals.app_infrastructure.enable_sqs_dlq
  dlq_name          = "${local.common_vars.locals.sqs_dlq_name}-${local.account_name}"
  max_receive_count = local.common_vars.locals.app_infrastructure.sqs_max_receive_count
  
  # Tags
  tags = merge(
    local.common_vars.locals.default_tags,
    {
      Environment = local.account_name
      Application = "node-example"
      Service     = "sqs-messaging"
      Region      = local.aws_region
      ManagedBy   = "Terragrunt"
    }
  )
}