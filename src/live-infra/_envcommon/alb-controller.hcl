# ---------------------------------------------------------------------------------------------------------------------
# COMMON AWS LOAD BALANCER CONTROLLER CONFIGURATION
# This is the common component configuration for AWS Load Balancer Controller. The common variables for each environment to
# deploy ALB Controller are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Expose the base source URL so different versions of the module can be deployed in different environments
  base_source_url = "${get_repo_root()}/src/infra-modules/services/helm-deploy"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # Helm configuration
  release_name     = "aws-load-balancer-controller"
  chart_name       = "aws-load-balancer-controller"
  chart_repository = "https://aws.github.io/eks-charts"
  chart_version    = "1.6.2"
  namespace        = "kube-system"
  
  # Controller version
  controller_version = "2.13.3"
  
  # Service account configuration
  create_service_account = false
  service_account_name   = "aws-load-balancer-controller"
  
  # Deployment settings
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600
  
  # Don't create namespace (kube-system already exists)
  create_namespace = false
}