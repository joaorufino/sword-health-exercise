# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (used for security group rules)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the EKS control plane will be deployed. Should be private subnets in multiple AZs."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of EKS control plane logging types to enable. Set to empty list to disable CloudWatch logging and save costs."
  type        = list(string)
  default     = []
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events in CloudWatch"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS Key ID to use for encrypting CloudWatch logs"
  type        = string
  default     = null
}

variable "enable_irsa" {
  description = "Whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "eks_addons" {
  description = "Map of EKS add-ons to enable"
  type        = map(any)
  default = {
    coredns = {
      version = "v1.10.1-eksbuild.6"
    }
    kube-proxy = {
      version = "v1.28.4-eksbuild.1"
    }
    vpc-cni = {
      version = "v1.15.4-eksbuild.1"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# TAGS
# ---------------------------------------------------------------------------------------------------------------------

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "Additional tags to apply to the EKS cluster"
  type        = map(string)
  default     = {}
}