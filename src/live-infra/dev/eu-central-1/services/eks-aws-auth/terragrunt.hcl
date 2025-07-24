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
  source = "${get_repo_root()}/src/infra-modules/services/eks/eks-aws-auth"
}

# Configure the kubernetes provider to connect to the EKS cluster
generate "kubernetes_provider" {
  path      = "kubernetes_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

data "aws_eks_cluster" "main" {
  name = "${local.name_prefix}-${local.account_name}-eks"
}

data "aws_eks_cluster_auth" "main" {
  name = "${local.name_prefix}-${local.account_name}-eks"
}
EOF
}

# Dependencies
dependency "eks_cluster" {
  config_path = "../eks-control-plane"
  
  mock_outputs = {
    cluster_name = "${local.name_prefix}-${local.account_name}-eks"
  }
}

dependency "eks_node_group" {
  config_path = "../eks-node-group"
  
  mock_outputs = {
    node_group_role_arn = "arn:aws:iam::${local.account_id}:role/${local.name_prefix}-${local.account_name}-eks-node-group-role"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  # Worker node roles - required for nodes to join cluster
  eks_worker_node_role_arns = [
    dependency.eks_node_group.outputs.node_group_role_arn
  ]
  
  # Admin roles - get system:masters access
  admin_role_names = [
    "${local.name_prefix}-admin"
  ]
  
  # Labels for the ConfigMap
  config_map_labels = {
    ManagedBy   = "Terragrunt"
    Environment = local.account_name
    Region      = local.aws_region
  }
}