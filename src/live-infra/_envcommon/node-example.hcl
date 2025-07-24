# ---------------------------------------------------------------------------------------------------------------------
# COMMON NODE EXAMPLE APPLICATION CONFIGURATION
# This is the common component configuration for the node-example application. The common variables for each environment to
# deploy node-example are defined here. This configuration will be merged into the environment configuration
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
  chart_name       = "${get_repo_root()}/src/kube-apps/charts/node-example"
  chart_repository = null  # This is a local chart
  chart_version    = "0.1.0"
  
  # Namespace configuration
  namespace        = "node-example"
  create_namespace = true
  namespace_labels = {
    "app.kubernetes.io/name" = "node-example"
  }
  
  # Service account configuration
  create_service_account = true
  service_account_name   = "node-example"
  
  # Deployment settings
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300
}