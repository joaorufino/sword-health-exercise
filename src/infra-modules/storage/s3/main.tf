# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# S3 BUCKET MODULE
# This module creates a secure S3 bucket with best practices enforced by default:
# - Public access blocked
# - Encryption enabled (SSE-S3 or KMS)
# - Versioning configurable
# - HTTPS-only access enforced
# - Lifecycle rules support
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ======================================================================================================================
# S3 BUCKET RESOURCE
# ======================================================================================================================

resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.common_tags
}

# ======================================================================================================================
# BUCKET SECURITY CONFIGURATION
# ======================================================================================================================

# ----------------------------------------------------------------------------------------------------------------------
# BLOCK PUBLIC ACCESS
# Ensure the bucket cannot be made public accidentally
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------------------------------------------------------------------------------------------
# BUCKET VERSIONING
# Enable versioning to protect against accidental deletion and provide object history
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# BUCKET ENCRYPTION
# Enable server-side encryption using either SSE-S3 (AES256) or SSE-KMS
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

# ======================================================================================================================
# LIFECYCLE MANAGEMENT
# ======================================================================================================================

# ----------------------------------------------------------------------------------------------------------------------
# LIFECYCLE RULES
# Configure automatic transitions and expiration for objects
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.key
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Filter is required - apply to all objects by default if no prefix specified
      filter {
        prefix = lookup(rule.value, "prefix", "")
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration_days", null) != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_days", null) != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_days
        }
      }
    }
  }
}

# ======================================================================================================================
# BUCKET POLICY
# ======================================================================================================================

# ----------------------------------------------------------------------------------------------------------------------
# BUCKET POLICY RESOURCE
# Apply the security policy to the bucket
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# ----------------------------------------------------------------------------------------------------------------------
# BUCKET POLICY DOCUMENT
# Define the security policy for the bucket
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "bucket_policy" {
  # Deny non-HTTPS requests
  statement {
    sid     = "DenyInsecureConnections"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Additional custom policy statements
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      sid       = statement.key
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = [for r in statement.value.resources : r == "self" ? aws_s3_bucket.main.arn : r == "self/*" ? "${aws_s3_bucket.main.arn}/*" : r]

      dynamic "principals" {
        for_each = lookup(statement.value, "principals", {})
        content {
          type        = principals.key
          identifiers = principals.value
        }
      }

      dynamic "condition" {
        for_each = lookup(statement.value, "conditions", [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}