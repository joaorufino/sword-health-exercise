# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "role_arn" {
  description = "ARN of the IAM role for the ALB controller"
  value       = aws_iam_role.alb_controller.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.alb_controller.name
}

output "policy_arn" {
  description = "ARN of the IAM policy"
  value       = aws_iam_policy.alb_controller.arn
}

output "service_account_annotation" {
  description = "Annotation to add to the Kubernetes service account"
  value = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
  }
}