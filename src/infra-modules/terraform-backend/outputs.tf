output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "access_logging_bucket_name" {
  description = "Name of the S3 bucket for access logs"
  value       = var.create_access_logging_bucket ? aws_s3_bucket.access_logging[0].id : null
}

output "backend_config" {
  description = "Backend configuration to use in other Terraform configurations"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "path/to/your/terraform.tfstate"  # This should be customized per module
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    encrypt        = true
  }
}