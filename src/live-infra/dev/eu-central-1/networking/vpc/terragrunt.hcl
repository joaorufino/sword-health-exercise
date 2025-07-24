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
  
  # VPC specific configuration
  vpc_cidr = local.common_vars.locals.vpc_cidrs[local.account_name]
  
  # Load security group rules from YAML with template variables
  security_groups_config = yamldecode(templatefile("${get_terragrunt_dir()}/security-groups.yaml", {
    vpc_cidr = local.vpc_cidr
  }))
}

terraform {
  source = "${get_repo_root()}/src/infra-modules/networking/vpc"
}

inputs = {
  # VPC configuration
  vpc_name = "${local.name_prefix}-${local.account_name}-vpc"
  vpc_cidr = local.vpc_cidr

  # Use 3 AZs for high availability
  num_availability_zones = local.common_vars.locals.azs_count

  # Subnet CIDRs from common configuration
  public_subnet_cidrs  = local.common_vars.locals.vpc_subnets[local.account_name].public
  private_subnet_cidrs = local.common_vars.locals.vpc_subnets[local.account_name].private
  data_subnet_cidrs    = local.common_vars.locals.vpc_subnets[local.account_name].data

  # For dev environment, use single NAT gateway to save costs
  single_nat_gateway = local.account_name == "dev" ? true : false

  # Enable S3 endpoint by default
  enable_s3_endpoint = true

  # Disable data subnet internet access for security
  enable_data_subnet_internet_access = false

  # Enable public IP assignment for instances in public subnets (needed for ALB)
  map_public_ip_on_launch = true

  # Security group rules from YAML
  private_security_group_ingress_rules = local.security_groups_config.private_security_group_ingress_rules
  data_security_group_ingress_rules    = local.security_groups_config.data_security_group_ingress_rules
  public_security_group_ingress_rules  = local.security_groups_config.public_security_group_ingress_rules
  
  # Use the same egress rules for all security groups
  default_security_group_egress_rules = local.security_groups_config.default_egress_rules
  public_security_group_egress_rules  = local.security_groups_config.default_egress_rules
  private_security_group_egress_rules = local.security_groups_config.default_egress_rules
  data_security_group_egress_rules    = local.security_groups_config.default_egress_rules

  # Tags
  common_tags = merge(
    local.common_vars.locals.default_tags,
    {
      Environment = local.account_name
      Region      = local.aws_region
      ManagedBy   = "Terragrunt"
    }
  )

  vpc_tags = {
    "kubernetes.io/cluster/${local.name_prefix}-${local.account_name}-eks" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                                                = "1"
    "kubernetes.io/cluster/${local.name_prefix}-${local.account_name}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                                       = "1"
    "kubernetes.io/cluster/${local.name_prefix}-${local.account_name}-eks" = "shared"
  }
}
