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
  source = "${get_repo_root()}/src/infra-modules/services/eks/eks-node-group"
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
  
  mock_outputs = {
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-1", "subnet-2", "subnet-3"]
  }
}

dependency "eks" {
  config_path = "../eks-control-plane"
  
  mock_outputs = {
    cluster_id      = "mock-cluster"
    cluster_version = "1.28"
  }
}

# Input variables
inputs = {
  cluster_name       = dependency.eks.outputs.cluster_id
  kubernetes_version = dependency.eks.outputs.cluster_version
  
  # Node group configurations - cost optimized for dev
  node_groups = {
    general = {
      subnet_ids     = dependency.vpc.outputs.private_subnet_ids
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      
      # Cost optimization: Use spot instances for dev
      capacity_type  = "SPOT"
      instance_types = ["t3.medium", "t3a.medium", "t2.medium", "t3.small", "t3a.small", "t2.small"]
      
      disk_size = 20
      ami_type  = "AL2_x86_64"
      
      labels = {
        role = "general"
        environment = local.account_name
      }
      
      taints = []
      
      tags = {
        NodeGroup = "general"
      }
    }
  }
  
  enable_ssm = true
  
  common_labels = {
    managed-by = "terragrunt"
  }
  
  common_tags = merge(
    local.common_vars.locals.default_tags,
    {
      Environment = local.account_name
      Region      = local.aws_region
      ManagedBy   = "Terragrunt"
      Service     = "eks-nodes"
    }
  )
}