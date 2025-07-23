# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE RDS DATABASE INSTANCE
# Simple RDS instance with encrypted password storage and VPC integration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Default ports for different engines
  default_ports = {
    mysql    = 3306
    mariadb  = 3306
    postgres = 5432
  }

  port = coalesce(var.port, local.default_ports[var.engine])
}

# ---------------------------------------------------------------------------------------------------------------------
# GENERATE AND STORE PASSWORD
# ---------------------------------------------------------------------------------------------------------------------

resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_password" {
  name_prefix = "${var.identifier}-password-"
  description = "Master password for RDS instance ${var.identifier}"

  recovery_window_in_days = var.secret_recovery_window_days
  kms_key_id              = var.kms_key_id

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = var.engine
    host     = aws_db_instance.main.address
    port     = local.port
    dbname   = var.database_name
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SUBNET GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${var.identifier}-subnet-group"
  description = "Database subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SECURITY GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name_prefix = "${var.identifier}-rds-"
  description = "Security group for RDS instance ${var.identifier}"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-rds"
    }
  )
}

# Allow ingress from specified security groups
resource "aws_security_group_rule" "ingress_from_security_groups" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.rds.id
  description              = "Allow database access from security group"
}

# Allow ingress from VPC CIDR for internal access
resource "aws_security_group_rule" "ingress_from_vpc" {
  count = var.allow_from_vpc_cidr ? 1 : 0

  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.rds.id
  description       = "Allow database access from VPC"
}

# No egress rules needed for RDS - AWS manages the connection to AWS services internally

# ---------------------------------------------------------------------------------------------------------------------
# CREATE RDS INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier = var.identifier

  # Engine
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.enable_storage_autoscaling ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id

  # Database
  db_name  = var.database_name
  port     = local.port
  username = var.master_username
  password = random_password.master.result

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-${formatdate("YYYYMMDD-hhmm", timestamp())}"

  # Maintenance
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  # High availability
  multi_az = var.multi_az

  # Monitoring - disabled by default for cost savings
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # IAM database authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Deletion protection
  deletion_protection = var.deletion_protection

  tags = var.tags

  lifecycle {
    ignore_changes = [password]
  }
}