include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/rds-mysql.hcl"
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

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
  
  mock_outputs = {
    vpc_id                    = "vpc-12345678"
    vpc_cidr_block            = "10.0.0.0/16"
    data_subnet_ids           = ["subnet-1", "subnet-2", "subnet-3"]
    private_security_group_id = "sg-12345678"
  }
}

dependency "eks" {
  config_path = "../../services/eks-control-plane"
  
  mock_outputs = {
    cluster_security_group_id = "sg-87654321"
  }
}

dependency "eks_node_group" {
  config_path = "../../services/eks-node-group"
  
  mock_outputs = {
    node_group_primary_security_group_id = "sg-12345678"
    node_group_security_group_ids = {
      general = ["sg-12345678"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

# These inputs get merged with the common inputs from the envcommon rds-mysql.hcl
inputs = {
  # Environment-specific configuration
  identifier = "${local.name_prefix}-${local.account_name}-mysql"
  instance_class = "db.t3.micro"  # Small instance for dev that supports IAM auth
  
  # Storage
  allocated_storage          = 20   # Start small for dev
  storage_type              = "gp3"
  enable_storage_autoscaling = true
  max_allocated_storage     = 50   # Allow growth up to 50GB
  
  # Network
  vpc_id              = dependency.vpc.outputs.vpc_id
  vpc_cidr_block      = dependency.vpc.outputs.vpc_cidr_block
  subnet_ids          = dependency.vpc.outputs.data_subnet_ids
  
  # Allow access from private subnet (where EKS nodes and applications run)
  # and from EKS cluster security group (for pods)
  # and from EKS node group security group (for node-level access)
  allowed_security_group_ids = concat(
    [
      dependency.vpc.outputs.private_security_group_id,
      dependency.eks.outputs.cluster_security_group_id,
    ],
    # Include the primary node group security group if it exists
    dependency.eks_node_group.outputs.node_group_primary_security_group_id != null ? [dependency.eks_node_group.outputs.node_group_primary_security_group_id] : []
  )
  
  # For dev, we can disable VPC-wide access since we're using security groups
  allow_from_vpc_cidr = false
  
  # Backup configuration
  backup_retention_period = 7  # 7 days for dev
  backup_window          = "03:00-04:00"  # 3-4 AM UTC
  maintenance_window     = "sun:04:00-sun:05:00"  # Sunday 4-5 AM UTC
  
  # High availability - disabled for dev to save costs
  multi_az = false
  
  # Security
  deletion_protection = false  # Allow deletion in dev
  skip_final_snapshot = true   # Skip final snapshot in dev
  
  # Monitoring - disabled for dev to save costs
  enabled_cloudwatch_logs_exports = []
  
  # Port
  port = 3306
  
  # Tags
  tags = merge(
    local.common_vars.locals.default_tags,
    {
      Environment = local.account_name
      Service     = "rds-mysql"
      Engine      = "mysql"
      Region      = local.aws_region
      ManagedBy   = "Terragrunt"
    }
  )
}