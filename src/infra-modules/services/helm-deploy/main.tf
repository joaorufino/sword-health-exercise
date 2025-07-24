# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY HELM CHARTS TO KUBERNETES
# Simple module for deploying Helm charts to EKS clusters
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24"
    }
  }
}

# Note: The Kubernetes and Helm providers must be configured by the caller
# This module expects the providers to be already configured with proper authentication

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE NAMESPACE
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_namespace" "main" {
  count = var.create_namespace && var.namespace != "default" && var.namespace != "kube-system" ? 1 : 0

  metadata {
    name = var.namespace
    labels = merge(
      var.namespace_labels,
      {
        "managed-by" = "terraform"
      }
    )
    annotations = var.namespace_annotations
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SERVICE ACCOUNT (FOR IRSA)
# ---------------------------------------------------------------------------------------------------------------------

resource "kubernetes_service_account" "main" {
  count = var.create_service_account ? 1 : 0

  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    labels = merge(
      {
        "app.kubernetes.io/name"       = var.release_name
        "app.kubernetes.io/managed-by" = "terraform"
      },
      var.service_account_labels
    )
    annotations = merge(
      var.irsa_role_arn != "" ? {
        "eks.amazonaws.com/role-arn" = var.irsa_role_arn
      } : {},
      var.service_account_annotations
    )
  }

  depends_on = [kubernetes_namespace.main]
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY HELM CHART
# ---------------------------------------------------------------------------------------------------------------------

resource "helm_release" "main" {
  name       = var.release_name
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.namespace

  # Don't create namespace - we handle it separately
  create_namespace = false

  # Deployment settings
  atomic          = var.atomic
  cleanup_on_fail = var.cleanup_on_fail
  wait            = var.wait
  wait_for_jobs   = var.wait_for_jobs
  timeout         = var.timeout
  max_history     = var.max_history
  recreate_pods   = var.recreate_pods
  force_update    = var.force_update

  # Values
  values = var.values_files

  # Merge all value configurations
  dynamic "set" {
    for_each = merge(
      var.set_values,
      var.create_service_account ? {
        "serviceAccount.create" = "false"
        "serviceAccount.name"   = var.service_account_name
      } : {}
    )
    content {
      name  = set.key
      value = set.value
    }
  }

  # Sensitive values
  dynamic "set_sensitive" {
    for_each = var.set_sensitive_values
    content {
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }

  depends_on = [
    kubernetes_namespace.main,
    kubernetes_service_account.main
  ]
}