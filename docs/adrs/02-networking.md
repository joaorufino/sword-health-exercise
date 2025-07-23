# Networking Architecture

- VPC with 3 subnets: public (ALB), private (EKS nodes), database (RDS)
- NAT Gateway in public subnet for outbound traffic from private resources
- For starting allow access to the EKS cluster block it for delivery
- No direct internet access to RDS
