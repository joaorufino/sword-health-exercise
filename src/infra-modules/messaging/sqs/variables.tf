# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "queue_name" {
  description = "The name of the queue. Module will append .fifo if fifo_queue is true."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "fifo_queue" {
  description = "Boolean designating a FIFO queue"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue (0-43200 seconds)"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Number of seconds SQS retains a message (60-1209600)"
  type        = number
  default     = 345600 # 4 days
}

variable "delay_seconds" {
  description = "Time in seconds that delivery of messages is delayed (0-900)"
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "Time for which ReceiveMessage waits for messages (0-20)"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024-262144)"
  type        = number
  default     = 262144 # 256 KiB
}

variable "kms_key_id" {
  description = "ID of KMS key for encryption. If null, no encryption."
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period" {
  description = "Seconds SQS can reuse data key (60-86400)"
  type        = number
  default     = 300
}

variable "enable_dlq" {
  description = "Enable dead letter queue"
  type        = bool
  default     = false
}

variable "max_receive_count" {
  description = "Max receives before sending to DLQ"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "DLQ message retention in seconds"
  type        = number
  default     = 1209600 # 14 days
}

variable "policy_statements" {
  description = "Policy statements for the queue"
  type = map(object({
    effect     = string
    actions    = list(string)
    principals = optional(map(list(string)), {})
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "dlq_tags" {
  description = "Additional tags for DLQ"
  type        = map(string)
  default     = {}
}