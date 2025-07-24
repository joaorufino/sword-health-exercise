# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_issuer_url" {
  description = "URL of the OIDC issuer for the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where the service account will be created"
  type        = string
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "s3_buckets" {
  description = "List of S3 buckets with their permissions"
  type = list(object({
    bucket_arn  = string
    permissions = list(string)
  }))
  default = []
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue to grant access to"
  type        = string
  default     = ""
}

variable "sqs_permissions" {
  description = "List of SQS permissions to grant"
  type        = list(string)
  default = [
    "sqs:SendMessage",
    "sqs:ReceiveMessage",
    "sqs:DeleteMessage",
    "sqs:GetQueueAttributes"
  ]
}

variable "enable_rds_iam_auth" {
  description = "Enable IAM database authentication for RDS"
  type        = bool
  default     = false
}

variable "rds_resource_id" {
  description = "Resource ID of the RDS instance (db-XXXXXXXXXXXXXXXXXXXX)"
  type        = string
  default     = ""
}

variable "rds_db_username" {
  description = "Database username for IAM authentication"
  type        = string
  default     = ""
}


variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}