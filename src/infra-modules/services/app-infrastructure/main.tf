# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE IRSA ROLE FOR APPLICATION
# This module creates an IAM role for Kubernetes Service Account with permissions to access S3 and SQS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# IRSA TRUST POLICY
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "app_role" {
  name               = "${var.app_name}-${var.environment}-pod-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 ACCESS POLICY
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "s3_access" {
  count = length(var.s3_buckets) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = var.s3_buckets
    content {
      effect  = "Allow"
      actions = statement.value.permissions
      resources = [
        statement.value.bucket_arn,
        "${statement.value.bucket_arn}/*"
      ]
    }
  }
}

resource "aws_iam_policy" "s3_access" {
  count = length(var.s3_buckets) > 0 ? 1 : 0

  name        = "${var.app_name}-${var.environment}-s3-access"
  description = "S3 access for ${var.app_name}"
  policy      = data.aws_iam_policy_document.s3_access[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  count = length(var.s3_buckets) > 0 ? 1 : 0

  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

# ---------------------------------------------------------------------------------------------------------------------
# SQS ACCESS POLICY
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "sqs_access" {
  count = var.sqs_queue_arn != "" ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = var.sqs_permissions
    resources = [var.sqs_queue_arn]
  }
}

resource "aws_iam_policy" "sqs_access" {
  count = var.sqs_queue_arn != "" ? 1 : 0

  name        = "${var.app_name}-${var.environment}-sqs-access"
  description = "SQS access for ${var.app_name}"
  policy      = data.aws_iam_policy_document.sqs_access[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "sqs_access" {
  count = var.sqs_queue_arn != "" ? 1 : 0

  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.sqs_access[0].arn
}

# ---------------------------------------------------------------------------------------------------------------------
# RDS IAM DATABASE AUTHENTICATION POLICY
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "rds_access" {
  count = var.enable_rds_iam_auth && var.rds_resource_id != "" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = [
      "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_resource_id}/${var.rds_db_username}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances"
    ]
    resources = [
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:*"
    ]
  }
}

resource "aws_iam_policy" "rds_access" {
  count = var.enable_rds_iam_auth && var.rds_resource_id != "" ? 1 : 0

  name        = "${var.app_name}-${var.environment}-rds-access"
  description = "RDS IAM authentication for ${var.app_name}"
  policy      = data.aws_iam_policy_document.rds_access[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_access" {
  count = var.enable_rds_iam_auth && var.rds_resource_id != "" ? 1 : 0

  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.rds_access[0].arn
}