# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN SQS QUEUE
# Simple SQS queue with optional dead letter queue
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
# CREATE THE QUEUE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sqs_queue" "main" {
  name                        = var.fifo_queue ? "${var.queue_name}.fifo" : var.queue_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  max_message_size           = var.max_message_size

  kms_master_key_id                 = var.kms_key_id
  kms_data_key_reuse_period_seconds = var.kms_key_id != null ? var.kms_data_key_reuse_period : null

  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE DEAD LETTER QUEUE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name       = var.fifo_queue ? "${var.queue_name}-dlq.fifo" : "${var.queue_name}-dlq"
  fifo_queue = var.fifo_queue

  message_retention_seconds = var.dlq_message_retention_seconds

  kms_master_key_id                 = var.kms_key_id
  kms_data_key_reuse_period_seconds = var.kms_key_id != null ? var.kms_data_key_reuse_period : null

  tags = merge(var.tags, var.dlq_tags)
}

# ---------------------------------------------------------------------------------------------------------------------
# QUEUE POLICY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sqs_queue_policy" "main" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  queue_url = aws_sqs_queue.main.id
  policy    = data.aws_iam_policy_document.queue_policy[0].json
}

data "aws_iam_policy_document" "queue_policy" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = var.policy_statements
    content {
      sid       = statement.key
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = [aws_sqs_queue.main.arn]

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