# ---------------------------------------------------------------------------------------------------------------------
# COMMON EKS CONTROL PLANE CONFIGURATION
# This is the common component configuration for EKS control plane. The common variables for each environment to
# deploy EKS are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Expose the base source URL so different versions of the module can be deployed in different environments
  base_source_url = "${get_repo_root()}/src/infra-modules/services/eks/eks-control-plane"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  kubernetes_version = "1.33"
  
  eks_addons = {
    coredns = {
      version = "v1.12.2-eksbuild.4"
    }
    kube-proxy = {
      version = "v1.33.0-eksbuild.2"
    }
    vpc-cni = {
      version = "v1.19.6-eksbuild.7"
    }
  }
  
  endpoint_private_access = true
  endpoint_public_access  = true
  enable_irsa            = true
}
