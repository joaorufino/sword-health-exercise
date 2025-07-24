# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "node_group_ids" {
  description = "Map of node group names to IDs"
  value = {
    for name, ng in aws_eks_node_group.main :
    name => ng.id
  }
}

output "node_group_arns" {
  description = "Map of node group names to ARNs"
  value = {
    for name, ng in aws_eks_node_group.main :
    name => ng.arn
  }
}

output "node_group_statuses" {
  description = "Map of node group names to statuses"
  value = {
    for name, ng in aws_eks_node_group.main :
    name => ng.status
  }
}

output "node_group_asg_names" {
  description = "Map of node group names to Auto Scaling Group names"
  value = {
    for name, ng in aws_eks_node_group.main :
    name => try(ng.resources[0].autoscaling_groups[0].name, null)
  }
}

output "node_group_role_arn" {
  description = "ARN of the IAM role used by the node groups"
  value       = aws_iam_role.node_group.arn
}

output "node_group_role_name" {
  description = "Name of the IAM role used by the node groups"
  value       = aws_iam_role.node_group.name
}

output "node_group_resources" {
  description = "Resources associated with the EKS node groups"
  value = {
    for name, ng in aws_eks_node_group.main :
    name => ng.resources
  }
}

output "cluster_security_group_id" {
  description = "The cluster security group ID created by EKS"
  value       = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "node_group_security_group_ids" {
  description = "Security group IDs from node group resources"
  value = {
    for name, ng in aws_eks_node_group.main :
    name => try(ng.resources[0].remote_access_security_group_id, null)
  }
}

output "node_group_primary_security_group_id" {
  description = "The primary security group ID (cluster security group)"
  value       = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}