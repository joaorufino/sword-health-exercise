# Security Approach

Must have:
- Private EKS endpoint 
- IAM roles for service accounts (IRSA) for pod AWS permissions
- Security groups for resource isolation
- KMS keys for encryption at rest for RDS and EKS
- Bastion host for cluster access
- Network policies to block app pod from accessing other pods

Nice to have (just for show off):
- AWS Systems Manager Session Manager instead of bastion
