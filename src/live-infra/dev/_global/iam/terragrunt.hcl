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
  
  # Load YAML configurations with template variables
  roles_config    = yamldecode(templatefile("${get_terragrunt_dir()}/roles.yaml", {
    name_prefix = local.name_prefix
    account_id  = local.account_id
  }))
  
  groups_config   = yamldecode(templatefile("${get_terragrunt_dir()}/groups.yaml", {
    name_prefix = local.name_prefix
    account_id  = local.account_id
  }))
  
  users_config    = yamldecode(file("${get_terragrunt_dir()}/users.yaml"))
  
  policies_config = yamldecode(templatefile("${get_terragrunt_dir()}/policies.yaml", {
    name_prefix = local.name_prefix
    account_id  = local.account_id
    aws_region  = local.aws_region
  }))
}

terraform {
  source = "${get_repo_root()}/src/infra-modules/mgmt/iam"
}

inputs = {
  # Load configurations from YAML files
  roles           = local.roles_config
  groups          = local.groups_config
  users           = local.users_config
  custom_policies = local.policies_config
  
  # Common settings
  password_length = 8
  
}
