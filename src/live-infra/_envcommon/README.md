# Common Environment Configurations

This directory contains common Terragrunt configurations that are shared across multiple environments (dev, staging, prod).

## Structure

- `networking/` - Common network configurations (VPC, subnets, security groups)
- `services/` - Common service configurations (EKS, ECS, etc.)
- `data-stores/` - Common data storage configurations (RDS, S3, etc.)
- `mgmt/` - Common management configurations (bastion hosts, VPN, etc.)

## Usage

These configurations are included in environment-specific terragrunt.hcl files using the `include` block with the `expose = true` parameter to access the configuration values.

Example:
```hcl
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/networking/vpc.hcl"
  expose = true
}
```