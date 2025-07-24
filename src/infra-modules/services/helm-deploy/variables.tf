# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "release_name" {
  description = "Name of the Helm release"
  type        = string
}

variable "chart_name" {
  description = "Name of the Helm chart"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the release"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "chart_repository" {
  description = "Repository URL where the chart is located"
  type        = string
  default     = null
}

variable "chart_version" {
  description = "Version of the chart to install"
  type        = string
  default     = null
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "namespace_labels" {
  description = "Labels to apply to the namespace"
  type        = map(string)
  default     = {}
}

variable "namespace_annotations" {
  description = "Annotations to apply to the namespace"
  type        = map(string)
  default     = {}
}

# Service Account Configuration
variable "create_service_account" {
  description = "Create a service account for the release"
  type        = bool
  default     = false
}

variable "service_account_name" {
  description = "Name of the service account"
  type        = string
  default     = ""
}

variable "service_account_labels" {
  description = "Labels for the service account"
  type        = map(string)
  default     = {}
}

variable "service_account_annotations" {
  description = "Annotations for the service account"
  type        = map(string)
  default     = {}
}

variable "irsa_role_arn" {
  description = "IAM role ARN for IRSA (will be added to service account annotations)"
  type        = string
  default     = ""
}

# Helm Values
variable "values_files" {
  description = "List of values files to pass to Helm"
  type        = list(string)
  default     = []
}

variable "values_file_path" {
  description = "Path to a single values file (convenience variable)"
  type        = string
  default     = ""
}

variable "set_values" {
  description = "Map of values to set"
  type        = map(string)
  default     = {}
}

variable "set_sensitive_values" {
  description = "Map of sensitive values to set"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# Deployment Behavior
variable "atomic" {
  description = "Purge the release on failed install/upgrade"
  type        = bool
  default     = true
}

variable "cleanup_on_fail" {
  description = "Allow deletion of new resources on failed install/upgrade"
  type        = bool
  default     = true
}

variable "wait" {
  description = "Wait until all resources are ready"
  type        = bool
  default     = true
}

variable "wait_for_jobs" {
  description = "Wait until all Jobs are complete"
  type        = bool
  default     = false
}

variable "timeout" {
  description = "Timeout for Helm operations (in seconds)"
  type        = number
  default     = 300
}

variable "max_history" {
  description = "Maximum number of release versions to store"
  type        = number
  default     = 3
}

variable "recreate_pods" {
  description = "Force recreation of pods during upgrade"
  type        = bool
  default     = false
}

variable "force_update" {
  description = "Force resource updates through delete/recreate"
  type        = bool
  default     = false
}