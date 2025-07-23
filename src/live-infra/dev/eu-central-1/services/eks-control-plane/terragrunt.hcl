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
  source = "${get_repo_root()}/src/infra-modules/services/eks/eks-control-plane"
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
  
  mock_outputs = {
    vpc_id              = "vpc-12345678"
    vpc_cidr_block            = "10.0.0.0/16"
    private_subnet_ids  = ["subnet-1", "subnet-2", "subnet-3"]
  }
}

# Input variables
inputs = {
  cluster_name = "${local.name_prefix}-${local.account_name}-eks"
  vpc_id       = dependency.vpc.outputs.vpc_id
  vpc_cidr     = dependency.vpc.outputs.vpc_cidr_block
  subnet_ids   = dependency.vpc.outputs.private_subnet_ids
  
  kubernetes_version = "1.28"
  
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]  # Restrict this in production
  
  # Disable CloudWatch logs to save costs (comment out to enable)
  # https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  # enabled_cluster_log_types = ["api", "audit", "authenticator", "controlManager", "scheduler"]
  enabled_cluster_log_types = []
  
  enable_irsa = true
  
  # EKS add-ons with latest versions for EKS 1.28
  # To check latest versions: aws eks describe-addon-versions --kubernetes-version 1.28 --addon-name <addon-name>
  eks_addons = {
    coredns = {
      version = "v1.10.1-eksbuild.7"  
    }
    kube-proxy = {
      version = "v1.28.6-eksbuild.2"  
    }
    vpc-cni = {
      version = "v1.16.0-eksbuild.1"  
    }
  }
  
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
}
