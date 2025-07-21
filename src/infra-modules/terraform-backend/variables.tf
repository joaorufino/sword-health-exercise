variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the backend resources"
  type        = string
}

variable "state_bucket_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which to expire noncurrent object versions"
  type        = number
  default     = 90
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB table"
  type        = bool
  default     = true
}

variable "create_access_logging_bucket" {
  description = "Create a separate S3 bucket for access logging"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}