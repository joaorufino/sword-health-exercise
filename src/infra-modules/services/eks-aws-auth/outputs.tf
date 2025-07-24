# ---------------------------------------------------------------------------------------------------------------------
# MODULE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "config_map_name" {
  description = "The name of the ConfigMap created or updated"
  value       = var.aws_auth_config_map_name
}

output "config_map_namespace" {
  description = "The namespace of the ConfigMap"
  value       = var.aws_auth_config_map_namespace
}

output "worker_node_role_count" {
  description = "Number of worker node IAM roles mapped"
  value       = length(var.eks_worker_iam_role_arns)
}

output "fargate_role_count" {
  description = "Number of Fargate execution IAM roles mapped"
  value       = length(var.eks_fargate_profile_executor_iam_role_arns)
}

output "iam_role_count" {
  description = "Number of additional IAM roles mapped"
  value       = length(var.iam_role_to_rbac_group_mappings)
}

output "iam_user_count" {
  description = "Number of IAM users mapped"
  value       = length(var.iam_user_to_rbac_group_mappings)
}

output "role_mappings" {
  description = "The complete list of IAM role mappings"
  value       = local.final_role_mappings
  sensitive   = true
}

output "user_mappings" {
  description = "The complete list of IAM user mappings"
  value       = local.final_user_mappings
  sensitive   = true
}

output "config_map_data" {
  description = "The data content of the aws-auth ConfigMap"
  value = {
    mapRoles = yamlencode(local.final_role_mappings)
    mapUsers = length(local.final_user_mappings) > 0 ? yamlencode(local.final_user_mappings) : null
  }
  sensitive = true
}