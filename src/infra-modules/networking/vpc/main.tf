# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A VPC WITH PUBLIC, PRIVATE, AND DATA SUBNETS
# This Terraform module creates a VPC with 3 types of subnets across multiple availability zones:
# - Public subnets (one per AZ) - for resources that need direct internet access
# - Private subnets (one per AZ) - for application workloads
# - Data subnets (one per AZ) - for databases and data persistence layers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GET AVAILABILITY ZONES
# ---------------------------------------------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE VPC
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  instance_tenancy     = var.instance_tenancy

  tags = merge(
    {
      Name = var.vpc_name
    },
    var.vpc_tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE INTERNET GATEWAY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-igw"
    },
    var.common_tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE PUBLIC SUBNETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = var.num_availability_zones

  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.vpc_name}-public-${data.aws_availability_zones.available.zone_ids[count.index]}"
      Type = "public"
    },
    var.public_subnet_tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE PRIVATE SUBNETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = var.num_availability_zones

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = merge(
    {
      Name = "${var.vpc_name}-private-${data.aws_availability_zones.available.zone_ids[count.index]}"
      Type = "private"
    },
    var.private_subnet_tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE DATA SUBNETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "data" {
  count = var.num_availability_zones

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.data_subnet_cidrs[count.index]

  tags = merge(
    {
      Name = "${var.vpc_name}-data-${data.aws_availability_zones.available.zone_ids[count.index]}"
      Type = "data"
    },
    var.data_subnet_tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ELASTIC IPS FOR NAT GATEWAYS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : var.num_availability_zones
  domain = "vpc"

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-eip-${count.index}"
    },
    var.common_tags
  )

  depends_on = [aws_internet_gateway.main]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE NAT GATEWAYS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_nat_gateway" "main" {
  count = var.single_nat_gateway ? 1 : var.num_availability_zones

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-${count.index}"
    },
    var.common_tags
  )

  depends_on = [aws_internet_gateway.main]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE TABLES FOR PUBLIC SUBNETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-public-rt"
    },
    var.common_tags
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = var.num_availability_zones

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE TABLES FOR PRIVATE SUBNETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "private" {
  count = var.single_nat_gateway ? 1 : var.num_availability_zones

  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-private-rt-${count.index}"
    },
    var.common_tags
  )
}

resource "aws_route" "private_nat" {
  count = var.single_nat_gateway ? 1 : var.num_availability_zones

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count = var.num_availability_zones

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE TABLES FOR DATA SUBNETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "data" {
  count = var.single_nat_gateway ? 1 : var.num_availability_zones

  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-data-rt-${count.index}"
    },
    var.common_tags
  )
}

resource "aws_route" "data_nat" {
  count = var.enable_data_subnet_internet_access ? (var.single_nat_gateway ? 1 : var.num_availability_zones) : 0

  route_table_id         = aws_route_table.data[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "data" {
  count = var.num_availability_zones

  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.data[0].id : aws_route_table.data[count.index].id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

# Default security group for the VPC
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.default_security_group_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.default_security_group_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-default-sg"
    },
    var.common_tags
  )
}

# Security group for public subnets
resource "aws_security_group" "public" {
  name        = "${var.vpc_name}-public-sg"
  description = "Security group for public subnets"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.public_security_group_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.public_security_group_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-public-sg"
    },
    var.common_tags
  )
}

# Security group for private subnets
resource "aws_security_group" "private" {
  name        = "${var.vpc_name}-private-sg"
  description = "Security group for private subnets"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.private_security_group_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.private_security_group_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-private-sg"
    },
    var.common_tags
  )
}

# Security group for data subnets
resource "aws_security_group" "data" {
  name        = "${var.vpc_name}-data-sg"
  description = "Security group for data subnets"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.data_security_group_ingress_rules
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = lookup(ingress.value, "security_groups", null)
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      description     = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.data_security_group_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-data-sg"
    },
    var.common_tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE VPC ENDPOINTS (OPTIONAL)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = merge(
    {
      Name = "${var.vpc_name}-s3-endpoint"
    },
    var.common_tags
  )
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.public.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count = var.enable_s3_endpoint ? length(aws_route_table.private) : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.private[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_data" {
  count = var.enable_s3_endpoint ? length(aws_route_table.data) : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.data[count.index].id
}