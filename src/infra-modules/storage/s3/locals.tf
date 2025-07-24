# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LOCAL VALUES
# Computed values and transformations used throughout the module
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

locals {
  # Resource naming
  resource_name = var.bucket_name

  # Common tags to be applied to all resources
  common_tags = merge(
    var.tags,
    {
      Module = "storage/s3"
      Name   = local.resource_name
    }
  )

  # Encryption configuration
  encryption_type = var.kms_key_id != null ? "KMS" : "SSE-S3"

  # Computed bucket ARNs for policies
  bucket_arn         = "arn:aws:s3:::${var.bucket_name}"
  bucket_objects_arn = "${local.bucket_arn}/*"
}