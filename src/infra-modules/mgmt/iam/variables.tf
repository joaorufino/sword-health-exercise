variable "roles" {
  description = "Map of IAM roles to create"
  type        = any # Using any to handle YAML parsing flexibility
  default     = {}
}

variable "groups" {
  description = "Map of IAM groups to create"
  type        = any # Using any to handle YAML parsing flexibility
  default     = {}
}

variable "users" {
  description = "Map of IAM users to create"
  type        = any # Using any to handle YAML parsing flexibility
  default     = {}
}

variable "password_length" {
  description = "Length of generated passwords"
  type        = number
  default     = 20
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "custom_policies" {
  description = "Map of custom IAM policies to create"
  type        = any # Using any to handle YAML parsing flexibility
  default     = {}
}