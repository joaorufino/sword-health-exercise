# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for networking/vpc. The common variables for each environment to
# deploy networking/vpc are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "${get_repo_root()}/src/infra-modules/networking/vpc"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Extract the name prefix for easy access
  name_prefix = local.common_vars.locals.name_prefix

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract the account_name for easy access
  account_name = local.account_vars.locals.account_name

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the region for easy access
  aws_region = local.region_vars.locals.aws_region

  # Get the VPC CIDR for this account
  cidr_block = local.common_vars.locals.vpc_cidrs[local.account_name]
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  vpc_name   = "${local.name_prefix}-${local.account_name}"
  cidr_block = local.cidr_block
  
  # Number of availability zones to use
  azs_count = local.common_vars.locals.azs_count
  
  # Enable DNS settings
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Enable VPC flow logs
  enable_flow_logs = true
  
  # Subnet configurations
  subnet_configs = local.common_vars.locals.subnet_configs
  
  # Tags for EKS
  eks_cluster_names    = ["${local.name_prefix}-${local.account_name}"]
  tag_for_use_with_eks = true
}