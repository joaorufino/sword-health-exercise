# ---------------------------------------------------------------------------------------------------------------------
# OUTPUT VALUES
# ---------------------------------------------------------------------------------------------------------------------

output "config_map_name" {
  description = "Name of the aws-auth ConfigMap"
  value       = kubernetes_config_map.aws_auth.metadata[0].name
}

output "config_map_namespace" {
  description = "Namespace of the aws-auth ConfigMap"
  value       = kubernetes_config_map.aws_auth.metadata[0].namespace
}

output "worker_node_role_count" {
  description = "Number of worker node roles mapped"
  value       = length(var.eks_worker_node_role_arns)
}

output "admin_role_count" {
  description = "Number of admin roles mapped"
  value       = length(var.admin_role_names)
}