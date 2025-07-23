# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MODULE OUTPUTS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ======================================================================================================================
# BUCKET IDENTIFIERS
# ======================================================================================================================

output "id" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

# ======================================================================================================================
# BUCKET ENDPOINTS
# ======================================================================================================================

output "domain_name" {
  description = "The bucket domain name (e.g., bucket-name.s3.amazonaws.com)"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "regional_domain_name" {
  description = "The bucket region-specific domain name (e.g., bucket-name.s3.region.amazonaws.com)"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

# ======================================================================================================================
# BUCKET CONFIGURATION
# ======================================================================================================================

output "versioning_enabled" {
  description = "Whether versioning is enabled on the bucket"
  value       = var.enable_versioning
}

output "encryption_type" {
  description = "The type of encryption used (SSE-S3 or KMS)"
  value       = local.encryption_type
}

# ======================================================================================================================
# CONVENIENCE OUTPUTS
# ======================================================================================================================

output "bucket_name" {
  description = "The name of the bucket (alias for 'id' output)"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the bucket (alias for 'arn' output)"
  value       = aws_s3_bucket.main.arn
}