# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    subnet_ids     = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
    ami_type       = string
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags = map(string)
  }))
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version for the node groups. If null, uses the cluster's version."
  type        = string
  default     = null
}

variable "enable_ssm" {
  description = "Whether to attach SSM policy for node management"
  type        = bool
  default     = true
}

variable "common_labels" {
  description = "Kubernetes labels to apply to all node groups"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "AWS tags to apply to all resources"
  type        = map(string)
  default     = {}
}