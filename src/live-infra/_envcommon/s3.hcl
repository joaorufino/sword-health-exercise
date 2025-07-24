# ---------------------------------------------------------------------------------------------------------------------
# COMMON S3 BUCKET CONFIGURATION
# This is the common component configuration for S3 buckets. The common variables for each environment to
# deploy S3 are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Expose the base source URL so different versions of the module can be deployed in different environments
  base_source_url = "${get_repo_root()}/src/infra-modules/storage/s3"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  enable_versioning = true
  
  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}