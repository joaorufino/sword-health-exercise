# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MAP AWS IAM ROLES TO KUBERNETES RBAC GROUPS
# This module manages the aws-auth ConfigMap in EKS, handling both new and existing ConfigMaps gracefully
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# Check if aws-auth ConfigMap already exists
data "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.create_aws_auth ? 0 : 1

  metadata {
    name      = var.aws_auth_config_map_name
    namespace = var.aws_auth_config_map_namespace
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCALS FOR ROLE AND USER MAPPINGS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Parse existing mappings if ConfigMap exists
  existing_map_roles = try(
    yamldecode(data.kubernetes_config_map_v1_data.aws_auth[0].data["mapRoles"]),
    []
  )
  existing_map_users = try(
    yamldecode(data.kubernetes_config_map_v1_data.aws_auth[0].data["mapUsers"]),
    []
  )

  # Worker node mappings (required for EKS nodes to join)
  worker_node_mappings = [
    for arn in var.eks_worker_iam_role_arns : {
      rolearn  = arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]

  # Fargate pod execution role mappings
  fargate_role_mappings = [
    for arn in var.eks_fargate_profile_executor_iam_role_arns : {
      rolearn  = arn
      username = "system:node:{{SessionName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
        "system:node-proxier",
      ]
    }
  ]

  # Standard IAM role mappings
  iam_role_mappings = [
    for arn, config in var.iam_role_to_rbac_group_mappings : {
      rolearn  = arn
      username = try(config.username, replace(arn, "/.*\\/(.*)/", "$1"))
      groups   = try(config.groups, config)
    }
  ]

  # SSO role mappings
  iam_sso_role_mappings = [
    for arn, config in var.iam_sso_role_to_rbac_group_mappings : {
      rolearn  = arn
      username = try(config.username, "{{SessionName}}")
      groups   = try(config.groups, config)
    }
  ]

  # IAM user mappings
  iam_user_mappings = [
    for arn, config in var.iam_user_to_rbac_group_mappings : {
      userarn  = arn
      username = try(config.username, replace(arn, "/.*\\/(.*)/", "$1"))
      groups   = try(config.groups, config)
    }
  ]

  # Combine all mappings
  all_role_mappings = concat(
    local.worker_node_mappings,
    local.fargate_role_mappings,
    local.iam_role_mappings,
    local.iam_sso_role_mappings
  )

  # Merge with existing mappings if ConfigMap exists
  final_role_mappings = var.create_aws_auth ? local.all_role_mappings : concat(
    local.existing_map_roles,
    [for new_role in local.all_role_mappings : new_role
    if !contains([for existing in local.existing_map_roles : existing.rolearn], new_role.rolearn)]
  )

  final_user_mappings = var.create_aws_auth ? local.iam_user_mappings : concat(
    local.existing_map_users,
    [for new_user in local.iam_user_mappings : new_user
    if !contains([for existing in local.existing_map_users : existing.userarn], new_user.userarn)]
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE OR UPDATE THE aws-auth CONFIGMAP
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_config_map" "aws_auth" {
  count = var.create_aws_auth ? 1 : 0

  metadata {
    name      = var.aws_auth_config_map_name
    namespace = var.aws_auth_config_map_namespace
    labels    = var.config_map_labels
  }

  data = {
    mapRoles = yamlencode(local.final_role_mappings)
    mapUsers = length(local.final_user_mappings) > 0 ? yamlencode(local.final_user_mappings) : null
  }

  lifecycle {
    # Prevent accidental deletion of aws-auth which would break cluster access
    prevent_destroy = true
  }
}

# Update existing ConfigMap using kubectl through null_resource
resource "null_resource" "update_aws_auth" {
  count = var.create_aws_auth ? 0 : 1

  triggers = {
    role_mappings = yamlencode(local.final_role_mappings)
    user_mappings = yamlencode(local.final_user_mappings)
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl get configmap aws-auth -n kube-system -o yaml > /tmp/aws-auth-backup.yaml
      
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: ${var.aws_auth_config_map_name}
        namespace: ${var.aws_auth_config_map_namespace}
        labels:
          ${yamlencode(var.config_map_labels)}
      data:
        mapRoles: |
          ${indent(4, yamlencode(local.final_role_mappings))}
        ${length(local.final_user_mappings) > 0 ? "mapUsers: |\n          ${indent(4, yamlencode(local.final_user_mappings))}" : ""}
      EOF
    EOT
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# KUBERNETES MANIFEST APPROACH (ALTERNATIVE)
# Use this if you prefer a pure Terraform approach without kubectl
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_manifest" "aws_auth_patch" {
  count = var.use_kubernetes_manifest && !var.create_aws_auth ? 1 : 0

  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = var.aws_auth_config_map_name
      namespace = var.aws_auth_config_map_namespace
      labels    = var.config_map_labels
    }
    data = {
      mapRoles = yamlencode(local.final_role_mappings)
      mapUsers = length(local.final_user_mappings) > 0 ? yamlencode(local.final_user_mappings) : null
    }
  }

  field_manager {
    name            = "terraform-eks-aws-auth"
    force_conflicts = true
  }
}