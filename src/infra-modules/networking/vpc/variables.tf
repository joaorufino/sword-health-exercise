# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be set by the user.
# ---------------------------------------------------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the VPC. Used to tag resources."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables have defaults and may be overridden.
# ---------------------------------------------------------------------------------------------------------------------

variable "num_availability_zones" {
  description = "How many Availability Zones to use for the VPC. Must be at least 2."
  type        = number
  default     = 3
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "data_subnet_cidrs" {
  description = "List of CIDR blocks for data subnets"
  type        = list(string)
}

variable "enable_dns_support" {
  description = "Whether DNS resolution is supported for the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Whether instances launched in the VPC get public DNS hostnames"
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "single_nat_gateway" {
  description = "If true, create only one NAT Gateway and route all private subnet traffic through it. This is cheaper but less available."
  type        = bool
  default     = false
}

variable "enable_data_subnet_internet_access" {
  description = "If true, data subnets will have routes to NAT gateways for internet access. Usually false for data layer security."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUP RULES
# These variables define the security group rules for each subnet type.
# ---------------------------------------------------------------------------------------------------------------------

variable "default_security_group_ingress_rules" {
  description = "Ingress rules for the default security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "default_security_group_egress_rules" {
  description = "Egress rules for the default security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

variable "public_security_group_ingress_rules" {
  description = "Ingress rules for the public subnet security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from anywhere"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from anywhere"
    }
  ]
}

variable "public_security_group_egress_rules" {
  description = "Egress rules for the public subnet security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

variable "private_security_group_ingress_rules" {
  description = "Ingress rules for the private subnet security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "private_security_group_egress_rules" {
  description = "Egress rules for the private subnet security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

variable "data_security_group_ingress_rules" {
  description = "Ingress rules for the data subnet security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    security_groups = optional(list(string))
    cidr_blocks     = optional(list(string))
    description     = string
  }))
  default = []
}

variable "data_security_group_egress_rules" {
  description = "Egress rules for the data subnet security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC ENDPOINTS
# ---------------------------------------------------------------------------------------------------------------------

variable "enable_s3_endpoint" {
  description = "If true, create a VPC endpoint for S3"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------------------------------------------------
# TAGS
# ---------------------------------------------------------------------------------------------------------------------

variable "vpc_tags" {
  description = "Additional tags to apply to the VPC"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags to apply to public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags to apply to private subnets"
  type        = map(string)
  default     = {}
}

variable "data_subnet_tags" {
  description = "Additional tags to apply to data subnets"
  type        = map(string)
  default     = {}
}

variable "map_public_ip_on_launch" {
  description = "Whether to auto-assign public IP addresses to instances launched in public subnets"
  type        = bool
  default     = false
}