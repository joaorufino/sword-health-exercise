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
  eks_cluster_version = "1.28"
  eks_node_instance_types = {
    dev     = ["t3.medium"]
  }

  # RDS configuration
  rds_engine_version = "8.0.35"
  rds_instance_class = {
    dev     = "db.t3.micro"
  }
  rds_backup_retention_period = {
    dev     = 7
  }

  # Application configuration
  node_example_image = "swordhealth/node-example:latest"

  # S3 bucket names for application
  app_bucket_read_suffix  = "app-data-read"
  app_bucket_write_suffix = "app-data-write"

  # SQS queue configuration
  sqs_queue_name = "${local.name_prefix}-app-queue"
  sqs_dlq_name   = "${local.name_prefix}-app-dlq"


  # IP addresses allowed to access EKS API endpoint
  eks_ip_allow_list = [
    # "1.2.3.4/32",     # Admin user IP
    # "5.6.7.8/32",     # Test user IP
    # "10.0.0.0/8",     # Corporate network range (example)
  ]
  
  # IP addresses allowed for deployment operations (CI/CD, etc.)
  deployment_ip_allow_list = [
    # "9.10.11.12/32",  # GitHub Actions runner IP (if using self-hosted)
  ]

  # Tags
  default_tags = yamldecode(file("tags.yml"))
}
