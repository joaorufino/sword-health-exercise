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
  source = "${get_repo_root()}/src/infra-modules/services/app-infrastructure"
}

# Dependencies
dependency "eks" {
  config_path = "../eks-control-plane"
  
  mock_outputs = {
    oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  }
}

dependency "s3_readwrite" {
  config_path = "../../storage/node-example-s3"
  
  mock_outputs = {
    bucket_arn = "arn:aws:s3:::node-example-dev"
    bucket_name = "node-example-dev"
  }
}

dependency "s3_readonly" {
  config_path = "../../storage/node-example-s3-readonly"
  
  mock_outputs = {
    bucket_arn = "arn:aws:s3:::node-example-dev-readonly"
    bucket_name = "node-example-dev-readonly"
  }
}

dependency "sqs" {
  config_path = "../../messaging/node-example-sqs"
  
  mock_outputs = {
    queue_arn = "arn:aws:sqs:eu-central-1:123456789012:node-example-dev"
    queue_url = "https://sqs.eu-central-1.amazonaws.com/123456789012/node-example-dev"
  }
}

# Input variables
inputs = {
  app_name             = "node-example"
  environment          = local.account_name
  
  # OIDC configuration from EKS
  oidc_provider_arn    = dependency.eks.outputs.oidc_provider_arn
  oidc_issuer_url      = dependency.eks.outputs.oidc_issuer_url
  
  # Kubernetes configuration
  namespace            = "node-example"
  service_account_name = "node-example"
  
  # S3 configuration with different permissions for each bucket
  s3_buckets = [
    {
      bucket_arn = dependency.s3_readwrite.outputs.bucket_arn
      permissions = local.common_vars.locals.app_infrastructure.s3_permissions  # Full permissions from common.hcl
    },
    {
      bucket_arn = dependency.s3_readonly.outputs.bucket_arn
      permissions = local.common_vars.locals.app_infrastructure.s3_readonly_permissions  # Read-only permissions from common.hcl
    }
  ]
  
  # SQS configuration
  sqs_queue_arn   = dependency.sqs.outputs.queue_arn
  sqs_permissions = local.common_vars.locals.app_infrastructure.sqs_permissions
  
  # Tags
  tags = merge(
    local.common_vars.locals.default_tags,
    {
      Environment = local.account_name
      Application = "node-example"
      Service     = "app-infrastructure"
      Region      = local.aws_region
      ManagedBy   = "Terragrunt"
    }
  )
}

