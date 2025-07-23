# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "The database port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "The name of the database"
  value       = aws_db_instance.main.db_name
}

output "master_username" {
  description = "The master username"
  value       = aws_db_instance.main.username
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "The name of the subnet group"
  value       = aws_db_subnet_group.main.name
}

output "secret_arn" {
  description = "The ARN of the secret containing the database credentials"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "secret_name" {
  description = "The name of the secret containing the database credentials"
  value       = aws_secretsmanager_secret.db_password.name
}

output "resource_id" {
  description = "Resource ID of the RDS instance (needed for IAM authentication)"
  value       = aws_db_instance.main.resource_id
}

output "iam_auth_enabled" {
  description = "Whether IAM database authentication is enabled"
  value       = var.iam_database_authentication_enabled
}