# Terraform Backend Infrastructure
# Creates S3 bucket and DynamoDB table for Terraform state management

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.state_bucket_prefix}-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.state_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
      Description = "Terraform state storage"
    }
  )
}

# Enable versioning for state recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for old versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  count = var.enable_versioning ? 1 : 0
  
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}

# S3 bucket for access logging
resource "aws_s3_bucket" "access_logging" {
  count = var.create_access_logging_bucket ? 1 : 0
  
  bucket = "${var.state_bucket_prefix}-logs-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.state_bucket_prefix}-logs-${data.aws_caller_identity.current.account_id}"
      Description = "Access logs for Terraform state bucket"
    }
  )
}

# Enable versioning for logs bucket
resource "aws_s3_bucket_versioning" "access_logging" {
  count = var.create_access_logging_bucket ? 1 : 0
  
  bucket = aws_s3_bucket.access_logging[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access for logs bucket
resource "aws_s3_bucket_public_access_block" "access_logging" {
  count = var.create_access_logging_bucket ? 1 : 0
  
  bucket = aws_s3_bucket.access_logging[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable access logging
resource "aws_s3_bucket_logging" "terraform_state" {
  count = var.create_access_logging_bucket ? 1 : 0
  
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.access_logging[0].id
  target_prefix = "terraform-state/"
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "${var.dynamodb_table_name}-${var.name_prefix}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  server_side_encryption {
    enabled = true
  }
  
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.dynamodb_table_name}-${var.name_prefix}"
      Description = "Terraform state lock table"
    }
  )
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}