# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN EKS CLUSTER CONTROL PLANE
# This module creates an EKS cluster with the necessary IAM roles, security groups, and configurations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get TLS certificate for OIDC provider
data "tls_certificate" "eks" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ---------------------------------------------------------------------------------------------------------------------
# EKS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Ensure proper order of resource creation
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
    aws_cloudwatch_log_group.eks,
  ]

  tags = var.cluster_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eks" {
  count = length(var.enabled_cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = var.common_tags
}

# aws-auth ConfigMap is now managed by separate eks-aws-auth module

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE FOR EKS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = var.common_tags
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUP FOR EKS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-eks-cluster-sg"
    }
  )
}

# Allow all outbound traffic
resource "aws_security_group_rule" "eks_cluster_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster.id
}

# Allow inbound HTTPS from within VPC
resource "aws_security_group_rule" "eks_cluster_ingress_https_vpc" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.eks_cluster.id
  description       = "Allow HTTPS from VPC"
}

# ---------------------------------------------------------------------------------------------------------------------
# OIDC PROVIDER FOR IRSA (IAM Roles for Service Accounts)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = var.common_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# EKS ADDONS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eks_addon" "main" {
  for_each = var.eks_addons

  cluster_name = aws_eks_cluster.main.name
  addon_name   = each.key

  addon_version               = lookup(each.value, "version", null)
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", "OVERWRITE")
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)

  tags = var.common_tags
}