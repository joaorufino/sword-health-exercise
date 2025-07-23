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