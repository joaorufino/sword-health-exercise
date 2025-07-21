# Common configuration shared across all environments
locals {
  name_prefix    = "sword-health"
  default_region = "eu-central-1"

  account_ids = {
    dev     = "123456789012"
  }

  # S3 bucket names for Terraform state
  state_bucket_prefix = "${local.name_prefix}-terraform-state"

  # DynamoDB table for state locking
  dynamodb_table_name = "terraform-state-lock"

  # Common VPC CIDR blocks per environment
  vpc_cidrs = {
    dev     = "10.0.0.0/16"
  }

  # Subnet CIDR configuration
  subnet_configs = {
    public = {
      subnet_bits = 4  # /20 subnets (4096 IPs each)
      offset      = 0
    }
    private = {
      subnet_bits = 2  # /18 subnets (16384 IPs each)
      offset      = 4
    }
    database = {
      subnet_bits = 6  # /22 subnets (1024 IPs each)
      offset      = 8
    }
  }

  # Number of availability zones to use
  azs_count = 3

  # Bastion host configuration
  bastion_instance_type = "t3.micro"

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

  # Default tags applied to all resources
  default_tags = {
    Project     = "sword-health-platform"
    ManagedBy   = "terraform"
    Repository  = "sword-health-exercise"
    CostCenter  = "platform"
  }
}
