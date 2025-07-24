# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MODULE VARIABLES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ======================================================================================================================
# REQUIRED VARIABLES
# These variables must be provided when using this module
# ======================================================================================================================

variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with a letter or number, and can contain only lowercase letters, numbers, hyphens, and dots."
  }

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters long."
  }
}

# ======================================================================================================================
# OPTIONAL VARIABLES
# These variables have defaults and are optional
# ======================================================================================================================

# ----------------------------------------------------------------------------------------------------------------------
# BUCKET CONFIGURATION
# ----------------------------------------------------------------------------------------------------------------------

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket. Versioning allows you to preserve, retrieve, and restore every version of every object stored in the bucket."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow destroying the bucket even if it contains objects. Use with caution in production environments."
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------------------------------------------------
# ENCRYPTION CONFIGURATION
# ----------------------------------------------------------------------------------------------------------------------

variable "kms_key_id" {
  description = "The AWS KMS key ID to use for encryption. If null, uses SSE-S3 (AES256) encryption."
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------------------------------------------------
# LIFECYCLE CONFIGURATION
# ----------------------------------------------------------------------------------------------------------------------

variable "lifecycle_rules" {
  description = "Map of lifecycle rules for automatic object management. Each rule can specify transitions to different storage classes and expiration."
  type = map(object({
    enabled = bool
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days = optional(number)
    noncurrent_days = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules : contains(
        ["STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE", "GLACIER_IR"],
        try(rule.transitions[0].storage_class, "STANDARD_IA")
      )
    ])
    error_message = "Storage class must be one of: STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, GLACIER_IR."
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# ACCESS POLICY CONFIGURATION
# ----------------------------------------------------------------------------------------------------------------------

variable "policy_statements" {
  description = "Additional IAM policy statements for the bucket. Use 'self' in resources to reference this bucket."
  type = map(object({
    effect     = string
    actions    = list(string)
    resources  = list(string)
    principals = optional(map(list(string)), {})
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.policy_statements : contains(["Allow", "Deny"], v.effect)
    ])
    error_message = "Policy effect must be either 'Allow' or 'Deny'."
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# TAGGING
# ----------------------------------------------------------------------------------------------------------------------

variable "tags" {
  description = "A map of tags to apply to all resources in this module."
  type        = map(string)
  default     = {}
}