# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "eks_worker_node_role_arns" {
  description = "List of IAM role ARNs for EKS worker nodes. These roles need system:nodes permissions."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "admin_role_names" {
  description = "List of IAM role names that should have system:masters (admin) access to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "iam_user_mappings" {
  description = "Map of IAM user ARNs to list of Kubernetes groups they should belong to"
  type        = map(list(string))
  default     = {}
}

variable "config_map_labels" {
  description = "Labels to apply to the aws-auth ConfigMap"
  type        = map(string)
  default     = {}
}