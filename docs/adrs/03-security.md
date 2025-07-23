# Security Approach

Must have:
- EKS endpoint with public access restricted to specific IPs (KISS approach)
- IAM roles for service accounts (IRSA) for pod AWS permissions
- Security groups for resource isolation
- KMS keys for encryption at rest for RDS and EKS
- Network policies to block app pod from accessing other pods

## EKS Access Decision

After consideration, we've chosen to enable the EKS public endpoint with IP restrictions instead of a fully private endpoint. This approach:
- Simplifies access management (no VPN or bastion host needed)
- Maintains security by restricting access to specific whitelisted IPs
- Follows the KISS principle
- Reduces infrastructure complexity and cost

The public endpoint will be configured with:
- `endpoint_public_access = true`
- `endpoint_public_access_cidrs` containing only authorized IP addresses
- Private endpoint remains enabled for internal VPC access

Other solutions considered:
- Bastion host for cluster access (requires AMI builders and adds complexity)
- AWS SSM instead of bastion (costly and tightly coupled with AWS)
- VPN solution (additional infrastructure to maintain)
