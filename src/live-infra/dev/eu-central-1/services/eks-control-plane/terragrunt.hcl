include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/eks-control-plane.hcl"
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

# Configure the kubernetes provider to connect to the EKS cluster
generate "kubernetes_provider" {
  path      = "kubernetes_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
  experiments {
    manifest_resource = true
  }
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}
EOF
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
  
  mock_outputs = {
    vpc_id              = "vpc-12345678"
    vpc_cidr_block      = "10.0.0.0/16"
    private_subnet_ids  = ["subnet-1", "subnet-2", "subnet-3"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

# These inputs get merged with the common inputs from the envcommon eks-control-plane.hcl
inputs = {
  # Environment-specific configuration
  cluster_name = "${local.name_prefix}-${local.account_name}-eks"
  vpc_id       = dependency.vpc.outputs.vpc_id
  vpc_cidr     = dependency.vpc.outputs.vpc_cidr_block
  subnet_ids   = dependency.vpc.outputs.private_subnet_ids
  
  public_access_cidrs = local.common_vars.locals.eks_ip_allow_list
  
  # Disable CloudWatch logs to save costs in dev
  enabled_cluster_log_types = []
  
  common_tags = merge(
    local.common_vars.locals.default_tags,
    {
      Environment = local.account_name
      Region      = local.aws_region
      ManagedBy   = "Terragrunt"
    }
  )
  
  cluster_tags = {
    "kubernetes.io/cluster/${local.name_prefix}-${local.account_name}-eks" = "owned"
  }
  
# AWS Auth ConfigMap now managed by separate eks-aws-auth module
}
