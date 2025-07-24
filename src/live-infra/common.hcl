# Common configuration shared across all environments
locals {
  name_prefix    = "sword-health"
  default_region = "eu-central-1"

  # Centrally define all the AWS account IDs. We use JSON so that it can be readily parsed outside of Terraform.
  accounts = jsondecode(file("accounts.json"))
  account_ids = {
    for key, account_info in local.accounts : key => account_info.id
  }

  # S3 bucket names for Terraform state - will be suffixed with account name and region
  state_bucket_prefix = local.name_prefix

  # DynamoDB table for state locking
  dynamodb_table_name = "terraform-locks"

  # VPC CIDR blocks per environment
  vpc_cidrs = {
    dev = "10.0.0.0/16"
  }

  # Subnet CIDR blocks - explicitly defined for each environment
  # Each subnet type gets 3 subnets (one per AZ)
  vpc_subnets = {
    dev = {
      public = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
      private = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
      data = ["10.0.96.0/20", "10.0.112.0/20", "10.0.128.0/20"]
    }
  }

  # Number of availability zones to use
  azs_count = 3

  # EKS configuration
  eks_cluster_version = "1.33"  # Latest version as of July 2025

  # EKS add-on versions
  eks_addon_versions = {
    coredns    = "v1.11.4-eksbuild.2"
    kube_proxy = "v1.33.0-eksbuild.1"
    vpc_cni    = "v1.18.0-eksbuild.1"
  }

  # AWS Load Balancer Controller versions
  alb_controller_version       = "2.13.3"
  alb_controller_chart_version = "1.6.2"

  # Helm chart versions
  helm_chart_versions = {
    node_example                 = "0.1.0"
    aws_load_balancer_controller = "1.6.2"
  }

  # RDS configuration
  rds_engine_version = "8.0.35"
  rds_iam_database_authentication_enabled = true
  rds_iam_db_username = "admin"  # Temporarily set to admin to create IAM user

  # Application configuration
  #node_example_image = "swordhealth/node-example:0.0.1"
  node_example_image = "niplodim/sword-health-exercise:0.0.4"
  
  # S3 bucket names for application
  app_bucket_readwrite_name = "node-example"      # Will be suffixed with account name
  app_bucket_readonly_name  = "node-example"  # Will be suffixed with account name

  # SQS queue configuration
  sqs_queue_name = "node-example"   # Will be suffixed with account name
  sqs_dlq_name   = "node-example-dlq"   # Will be suffixed with account name

  # Application infrastructure defaults
  app_infrastructure = {
    s3_permissions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    s3_readonly_permissions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    sqs_permissions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:SendMessage",
      "sqs:GetQueueAttributes"
    ]
    enable_s3_versioning = true
    enable_sqs_dlq = true
    sqs_max_receive_count = 3
  }



  # IP addresses allowed to access EKS API endpoint
  eks_ip_allow_list = [
    "94.61.153.77/32",     # Office
    "161.230.217.223/32",     # Home
  ]

  # IP addresses allowed for deployment operations (CI/CD, etc.)
  deployment_ip_allow_list = [
    # "9.10.11.12/32",  # GitHub Actions runner IP (if using self-hosted)
  ]

  # Tags
  default_tags = yamldecode(file("tags.yml"))
}
