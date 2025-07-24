# ---------------------------------------------------------------------------------------------------------------------
# COMMON RDS MYSQL CONFIGURATION
# This is the common component configuration for RDS MySQL. The common variables for each environment to
# deploy RDS are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Expose the base source URL so different versions of the module can be deployed in different environments
  base_source_url = "${get_repo_root()}/src/infra-modules/storage/rds"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # Note: identifier will be set by the environment-specific configuration
  
  engine         = "mysql"
  engine_version = "8.0.35"
  
  database_name   = "application"
  master_username = "admin"
  
  storage_encrypted = true
  deletion_protection = false  # Will be overridden to true in prod
  
  # IAM authentication
  iam_database_authentication_enabled = true
  
  # Apply changes immediately instead of waiting for maintenance window
  # This ensures IAM authentication is enabled right away
  apply_immediately = true
}
