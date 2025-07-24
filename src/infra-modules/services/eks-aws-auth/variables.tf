# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "eks_worker_iam_role_arns" {
  description = "List of AWS ARNs of the IAM roles associated with the EKS worker nodes. Each IAM role passed in will be set up as a Node role in Kubernetes."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "create_aws_auth" {
  description = "Whether to create a new aws-auth ConfigMap. Set to false if aws-auth already exists in the cluster."
  type        = bool
  default     = true
}

variable "use_kubernetes_manifest" {
  description = "Use kubernetes_manifest resource instead of null_resource for updating existing ConfigMap. This is a pure Terraform approach but requires careful state management."
  type        = bool
  default     = false
}

variable "aws_auth_config_map_name" {
  description = "Name of the aws-auth ConfigMap. Must be 'aws-auth' unless using aws-auth-merger."
  type        = string
  default     = "aws-auth"
}

variable "aws_auth_config_map_namespace" {
  description = "Namespace for the aws-auth ConfigMap. Must be 'kube-system' unless using aws-auth-merger."
  type        = string
  default     = "kube-system"
}

variable "eks_fargate_profile_executor_iam_role_arns" {
  description = "List of AWS ARNs of the IAM roles associated with launching Fargate pods."
  type        = list(string)
  default     = []
}

variable "iam_role_to_rbac_group_mappings" {
  description = "Mapping of AWS IAM roles to RBAC groups. Can be a simple list of groups or an object with username and groups."
  type        = map(any)
  default     = {}
  # Example:
  # {
  #   "arn:aws:iam::123456789012:role/admin" = ["system:masters"]
  #   "arn:aws:iam::123456789012:role/developer" = {
  #     username = "developer-user"
  #     groups   = ["developers", "viewers"]
  #   }
  # }
}

variable "iam_sso_role_to_rbac_group_mappings" {
  description = "Mapping of AWS SSO roles to RBAC groups. Can be a simple list of groups or an object with username and groups."
  type        = map(any)
  default     = {}
  # Example:
  # {
  #   "arn:aws:iam::123456789012:role/AWSReservedSSO_AdminAccess_1234567890abcdef" = ["system:masters"]
  # }
}

variable "iam_user_to_rbac_group_mappings" {
  description = "Mapping of AWS IAM users to RBAC groups. Can be a simple list of groups or an object with username and groups."
  type        = map(any)
  default     = {}
  # Example:
  # {
  #   "arn:aws:iam::123456789012:user/alice" = ["developers"]
  #   "arn:aws:iam::123456789012:user/bob" = {
  #     username = "bob-custom"
  #     groups   = ["admins", "developers"]
  #   }
  # }
}

variable "config_map_labels" {
  description = "Map of labels to apply to the aws-auth ConfigMap."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# ADVANCED CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

variable "preserve_existing_mappings" {
  description = "When updating existing aws-auth, preserve mappings not managed by this module."
  type        = bool
  default     = true
}

variable "worker_node_security_group_ids" {
  description = "Security group IDs for worker nodes. Used for documentation purposes."
  type        = list(string)
  default     = []
}

variable "enable_config_map_backup" {
  description = "Create a backup of the existing aws-auth ConfigMap before updates."
  type        = bool
  default     = true
}