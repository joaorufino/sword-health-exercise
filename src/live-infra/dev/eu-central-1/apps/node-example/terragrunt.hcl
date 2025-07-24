include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  # Load account and common variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  # Extract commonly used variables
  account_name = local.account_vars.locals.account_name
  account_id   = local.common_vars.locals.account_ids[local.account_name]
  name_prefix  = local.common_vars.locals.name_prefix
  aws_region   = local.region_vars.locals.aws_region
  
  # Application configuration
  app_name = "node-example"
  namespace = "node-example"
}

terraform {
  source = "${get_repo_root()}/src/infra-modules/services/helm-deploy"
}

# Generate Kubernetes and Helm provider configuration
generate "k8s_providers" {
  path      = "k8s_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    data "aws_eks_cluster" "cluster" {
      name = var.eks_cluster_name
    }

    data "aws_eks_cluster_auth" "cluster" {
      name = var.eks_cluster_name
    }

    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }

    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.cluster.token
      }
    }
  EOF
}

# Dependencies
dependency "eks" {
  config_path = "../../services/eks-control-plane"
  
  mock_outputs = {
    cluster_id = "mock-cluster"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  }
}

dependency "app_infra" {
  config_path = "../../services/app-infrastructure"
  
  mock_outputs = {
    role_arn = "arn:aws:iam::${local.account_id}:role/node-example-${local.account_name}-pod-role"
  }
}

dependency "s3_readwrite" {
  config_path = "../../storage/node-example-s3"
  
  mock_outputs = {
    bucket_name = "node-example-dev"
  }
}

dependency "s3_readonly" {
  config_path = "../../storage/node-example-s3-readonly"
  
  mock_outputs = {
    bucket_name = "node-example-dev-readonly"
  }
}

dependency "sqs" {
  config_path = "../../messaging/node-example-sqs"
  
  mock_outputs = {
    queue_url = "https://sqs.eu-central-1.amazonaws.com/123456789012/node-example-dev"
  }
}

dependency "rds" {
  config_path = "../../storage/rds-mysql"
  
  mock_outputs = {
    endpoint = "mock-db.cluster-123456789012.eu-central-1.rds.amazonaws.com"
    port = 3306
    database_name = "appdb"
    master_username = "admin"
    password_secret_arn = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:mock-rds-password"
  }
}

# Input variables
inputs = {
  eks_cluster_name = dependency.eks.outputs.cluster_id
  
  # Helm configuration
  release_name     = local.app_name
  chart_name       = "${get_repo_root()}/src/kube-apps/charts/node-example"
  chart_repository = null  # This is a local chart
  chart_version    = "0.1.0"
  namespace        = local.namespace
  
  # Create namespace
  create_namespace = true
  namespace_labels = {
    "app.kubernetes.io/name" = local.app_name
    "environment"            = local.account_name
  }
  
  # Create service account with IRSA
  create_service_account = true
  service_account_name   = local.app_name
  irsa_role_arn         = dependency.app_infra.outputs.role_arn
  
  # Use values file with template variables
  values_files = [
    templatefile("${get_terragrunt_dir()}/values.yaml", {
      environment          = local.account_name
      aws_region          = local.aws_region
      image_repository    = split(":", local.common_vars.locals.node_example_image)[0]
      image_tag           = split(":", local.common_vars.locals.node_example_image)[1]
      app_domain          = "${local.app_name}.${local.account_name}.example.com"
      service_account_name = local.app_name
      irsa_role_arn       = dependency.app_infra.outputs.role_arn
      s3_bucket           = dependency.s3_readwrite.outputs.bucket_name
      s3_readonly_bucket  = dependency.s3_readonly.outputs.bucket_name
      sqs_queue_url       = dependency.sqs.outputs.queue_url
      # RDS configuration
      rds_endpoint        = dependency.rds.outputs.endpoint
      rds_port            = dependency.rds.outputs.port
      rds_database_name   = dependency.rds.outputs.database_name
      rds_username        = dependency.rds.outputs.master_username
      # Network configuration
      vpc_cidr            = local.common_vars.locals.vpc_cidrs[local.account_name]
    })
  ]
  
  # Deployment settings
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300
}