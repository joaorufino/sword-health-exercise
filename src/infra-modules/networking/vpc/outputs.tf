# ---------------------------------------------------------------------------------------------------------------------
# VPC OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.main.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# SUBNET OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "data_subnet_ids" {
  description = "List of IDs of data subnets"
  value       = aws_subnet.data[*].id
}

output "data_subnet_cidrs" {
  description = "List of CIDR blocks of data subnets"
  value       = aws_subnet.data[*].cidr_block
}

output "data_subnet_arns" {
  description = "List of ARNs of data subnets"
  value       = aws_subnet.data[*].arn
}

# ---------------------------------------------------------------------------------------------------------------------
# INTERNET GATEWAY OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "internet_gateway_arn" {
  description = "The ARN of the Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# NAT GATEWAY OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].public_ip
}

# ---------------------------------------------------------------------------------------------------------------------
# ROUTE TABLE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "data_route_table_ids" {
  description = "List of IDs of data route tables"
  value       = aws_route_table.data[*].id
}

# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUP OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_default_security_group.default.id
}

output "public_security_group_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.public.id
}

output "private_security_group_id" {
  description = "The ID of the private security group"
  value       = aws_security_group.private.id
}

output "data_security_group_id" {
  description = "The ID of the data security group"
  value       = aws_security_group.data.id
}

# ---------------------------------------------------------------------------------------------------------------------
# AVAILABILITY ZONE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC ENDPOINT OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "s3_endpoint_id" {
  description = "The ID of the S3 VPC endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}