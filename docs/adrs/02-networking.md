# Networking Architecture

- VPC with 3 subnets: public (ALB), private (EKS nodes), database (RDS)
- NAT Gateway in public subnet for outbound traffic from private resources
- No direct internet access to EKS or RDS