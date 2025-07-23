# Simple IAM Module - Create roles, groups, and users with minimal complexity

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Create IAM Roles
resource "aws_iam_role" "roles" {
  for_each = var.roles

  name                 = each.key
  description          = each.value.description
  max_session_duration = lookup(each.value, "max_session_duration", 3600)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = lookup(each.value, "trusted_entities", ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"])
        }
        Action = "sts:AssumeRole"
        Condition = merge(
          lookup(each.value, "require_mfa", false) ? {
            Bool = {
              "aws:MultiFactorAuthPresent" = "true"
            }
          } : {},
          length(lookup(each.value, "allowed_ips", [])) > 0 ? {
            IpAddress = {
              "aws:SourceIp" = each.value.allowed_ips
            }
          } : {}
        )
      }
    ]
  })

  tags = merge(var.default_tags, lookup(each.value, "tags", {}))
}

# Attach AWS managed policies to roles
resource "aws_iam_role_policy_attachment" "role_managed_policies" {
  for_each = {
    for item in local.role_managed_policy_attachments :
    "${item.role}-${item.policy}" => item
  }

  role       = aws_iam_role.roles[each.value.role].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value.policy}"
}

# Create IAM Groups
resource "aws_iam_group" "groups" {
  for_each = var.groups

  name = each.key
  path = "/"
}

# Attach AWS managed policies to groups
resource "aws_iam_group_policy_attachment" "group_managed_policies" {
  for_each = {
    for item in local.group_managed_policy_attachments :
    "${item.group}-${item.policy}" => item
  }

  group      = aws_iam_group.groups[each.value.group].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value.policy}"
}

# Create group policies for role assumption
resource "aws_iam_group_policy" "assume_role_policies" {
  for_each = {
    for item in local.group_role_mappings :
    "${item.group}-${item.role}" => item
  }

  name  = "AssumeRole-${each.value.role}"
  group = aws_iam_group.groups[each.value.group].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.roles[each.value.role].arn
      }
    ]
  })
}

# Create IAM Users
resource "aws_iam_user" "users" {
  for_each = var.users

  name          = each.key
  force_destroy = true

  tags = merge(var.default_tags, lookup(each.value, "tags", {}))
}

# Create login profiles for users who need console access
resource "aws_iam_user_login_profile" "login_profiles" {
  for_each = {
    for name, user in var.users :
    name => user
    if lookup(user, "create_login_profile", false)
  }

  user                    = aws_iam_user.users[each.key].name
  password_length         = var.password_length
  password_reset_required = true
}

# Create access keys for users who need programmatic access
resource "aws_iam_access_key" "access_keys" {
  for_each = {
    for name, user in var.users :
    name => user
    if lookup(user, "create_access_keys", false)
  }

  user = aws_iam_user.users[each.key].name
}

# Add users to groups
resource "aws_iam_user_group_membership" "memberships" {
  for_each = var.users

  user   = aws_iam_user.users[each.key].name
  groups = lookup(each.value, "groups", [])

  depends_on = [aws_iam_group.groups]
}

# Custom policies from YAML files
resource "aws_iam_policy" "custom_policies" {
  for_each = var.custom_policies

  name        = each.key
  description = each.value.description
  path        = "/"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = each.value.statements
  })

  tags = merge(var.default_tags, lookup(each.value, "tags", {}))
}

# Attach custom policies to roles
resource "aws_iam_role_policy_attachment" "role_custom_policies" {
  for_each = {
    for item in local.role_custom_policy_attachments :
    "${item.role}-${item.policy}" => item
  }

  role       = aws_iam_role.roles[each.value.role].name
  policy_arn = aws_iam_policy.custom_policies[each.value.policy].arn
}

# Attach custom policies to groups
resource "aws_iam_group_policy_attachment" "group_custom_policies" {
  for_each = {
    for item in local.group_custom_policy_attachments :
    "${item.group}-${item.policy}" => item
  }

  group      = aws_iam_group.groups[each.value.group].name
  policy_arn = aws_iam_policy.custom_policies[each.value.policy].arn
}

# Inline policies for roles (for role-specific permissions)
resource "aws_iam_role_policy" "inline_policies" {
  for_each = {
    for item in local.role_inline_policies :
    "${item.role}-${item.name}" => item
  }

  name = each.value.name
  role = aws_iam_role.roles[each.value.role].name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = each.value.statements
  })
}

# Inline policies for groups (for group-specific permissions)
resource "aws_iam_group_policy" "inline_policies" {
  for_each = {
    for item in local.group_inline_policies :
    "${item.group}-${item.name}" => item
  }

  name  = each.value.name
  group = aws_iam_group.groups[each.value.group].name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = each.value.statements
  })
}

# Locals for flattening nested structures
locals {
  # Flatten role managed policy attachments
  role_managed_policy_attachments = flatten([
    for role_name, role_config in var.roles : [
      for policy in lookup(role_config, "managed_policies", []) : {
        role   = role_name
        policy = policy
      }
    ]
  ])

  # Flatten group managed policy attachments
  group_managed_policy_attachments = flatten([
    for group_name, group_config in var.groups : [
      for policy in lookup(group_config, "managed_policies", []) : {
        group  = group_name
        policy = policy
      }
    ]
  ])

  # Flatten group to role mappings
  group_role_mappings = flatten([
    for group_name, group_config in var.groups : [
      for role in lookup(group_config, "assumable_roles", []) : {
        group = group_name
        role  = role
      }
    ]
  ])

  # Flatten role custom policy attachments
  role_custom_policy_attachments = flatten([
    for role_name, role_config in var.roles : [
      for policy in lookup(role_config, "custom_policies", []) : {
        role   = role_name
        policy = policy
      }
    ]
  ])

  # Flatten group custom policy attachments
  group_custom_policy_attachments = flatten([
    for group_name, group_config in var.groups : [
      for policy in lookup(group_config, "custom_policies", []) : {
        group  = group_name
        policy = policy
      }
    ]
  ])

  # Flatten role inline policies
  role_inline_policies = flatten([
    for role_name, role_config in var.roles : [
      for policy_name, policy_config in lookup(role_config, "inline_policies", {}) : {
        role       = role_name
        name       = policy_name
        statements = policy_config.statements
      }
    ]
  ])

  # Flatten group inline policies
  group_inline_policies = flatten([
    for group_name, group_config in var.groups : [
      for policy_name, policy_config in lookup(group_config, "inline_policies", {}) : {
        group      = group_name
        name       = policy_name
        statements = policy_config.statements
      }
    ]
  ])
}

data "aws_caller_identity" "current" {}