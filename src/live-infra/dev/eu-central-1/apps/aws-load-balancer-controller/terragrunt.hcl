include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/alb-controller.hcl"
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

# Generate Kubernetes and Helm provider configuration
generate "k8s_providers" {
  path      = "k8s_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    data "aws_eks_cluster" "cluster" {
      name = var.eks_cluster_name
    }

    data "aws_eks_cluster_auth" "cluster" {
      name = var.eks_cluster_name
    }

    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }

    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.cluster.token
      }
    }
  EOF
}

# Dependencies
dependency "eks" {
  config_path = "../../services/eks-control-plane"
  
  mock_outputs = {
    cluster_id = "mock-cluster"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  }
}

dependency "irsa" {
  config_path = "../../services/alb-controller-irsa"
  
  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/mock-alb-controller"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

# These inputs get merged with the common inputs from the envcommon alb-controller.hcl
inputs = {
  # Environment-specific configuration
  eks_cluster_name = dependency.eks.outputs.cluster_id
  irsa_role_arn    = dependency.irsa.outputs.role_arn
  
  # Helm values specific to this environment
  set_values = {
    "clusterName"                 = dependency.eks.outputs.cluster_id
    "region"                      = local.aws_region
    "vpcId"                       = dependency.vpc.outputs.vpc_id
    "serviceAccount.create"       = "false"
    "serviceAccount.name"         = "aws-load-balancer-controller"
    "enableServiceMutatorWebhook" = "false"
    "defaultTargetType"           = "ip"
    "defaultTags.Environment"     = local.account_name
    "defaultTags.ManagedBy"      = "Terragrunt"
  }
}

dependency "vpc" {
  config_path = "../../networking/vpc"
  
  mock_outputs = {
    vpc_id = "vpc-12345678"
  }
}