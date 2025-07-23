# User Management

## Overview

User access is managed through a YAML-driven IAM module that creates AWS IAM users, groups, roles, and policies.

Configuration files are in `src/live-infra/{environment}/_global/iam/`:
- `users.yaml` - User definitions with group assignments
- `groups.yaml` - Group definitions with permissions
- `roles.yaml` - Assumable roles with security policies
- `policies.yaml` - Custom IAM policies

## Architecture

Users → Groups → Roles/Policies

Users get permissions through:
1. Direct group membership (for basic permissions)
2. Role assumption (for elevated access with MFA)

## Usage

To add a new user:
1. Edit `src/live-infra/{environment}/_global/iam/users.yaml`
2. Add user email and group assignments
3. Apply Terragrunt changes

Example:
```yaml
user@example.com:
  groups:
    - developers
  create_login_profile: true
  create_access_keys: false
```

## Security Features

- MFA enforcement on sensitive roles
- IP-based access restrictions
- Forced password reset on first login
- Role-based access control (RBAC)