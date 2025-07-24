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
  name_prefix  = local.common_vars.locals.name_prefix
}

terraform {
  source = "${get_repo_root()}/src/infra-modules/services/alb-controller-irsa"
}

# Dependencies
dependency "eks" {
  config_path = "../eks-control-plane"
  
  mock_outputs = {
    cluster_id = "mock-cluster"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
    oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  }
}

# Input variables
inputs = {
  cluster_name      = dependency.eks.outputs.cluster_id
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_issuer_url   = dependency.eks.outputs.oidc_issuer_url
  
  # Controller configuration
  namespace            = "kube-system"
  service_account_name = "aws-load-balancer-controller"
  controller_version   = "2.13.3"
  
  # Tags
  tags = merge(
    local.common_vars.locals.default_tags,
    {
      Environment = local.account_name
      Service     = "alb-controller-irsa"
      Component   = "iam"
    }
  )
}