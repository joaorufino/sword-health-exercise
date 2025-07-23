# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MAP AWS IAM ROLES TO KUBERNETES RBAC GROUPS
# This module creates the `aws-auth` ConfigMap in the EKS cluster to map IAM roles/users to Kubernetes RBAC groups.
# Simplified version focusing on worker nodes and admin roles only.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.3"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE aws-auth CONFIGMAP
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels    = var.config_map_labels
  }

  data = {
    mapRoles = yamlencode(concat(local.worker_node_mappings, local.admin_role_mappings))
    mapUsers = length(var.iam_user_mappings) > 0 ? yamlencode(local.iam_user_mappings) : ""
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES FOR ROLE MAPPINGS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Worker node mappings - required for nodes to join the cluster
  worker_node_mappings = [
    for arn in var.eks_worker_node_role_arns : {
      rolearn  = arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]

  # Admin role mappings - IAM roles that get system:masters access
  admin_role_mappings = [
    for role_name in var.admin_role_names : {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role_name}"
      username = "${role_name}-user"
      groups   = ["system:masters"]
    }
  ]

  # IAM user mappings (optional)
  iam_user_mappings = [
    for arn, groups in var.iam_user_mappings : {
      userarn  = arn
      username = replace(arn, "/.*/(.*)/", "$1")
      groups   = groups
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}