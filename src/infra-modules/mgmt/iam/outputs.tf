output "roles" {
  description = "Created IAM roles"
  value = {
    for name, role in aws_iam_role.roles :
    name => {
      arn  = role.arn
      name = role.name
      id   = role.id
    }
  }
}

output "groups" {
  description = "Created IAM groups"
  value = {
    for name, group in aws_iam_group.groups :
    name => {
      arn  = group.arn
      name = group.name
      id   = group.id
    }
  }
}

output "users" {
  description = "Created IAM users"
  value = {
    for name, user in aws_iam_user.users :
    name => {
      arn       = user.arn
      name      = user.name
      unique_id = user.unique_id
    }
  }
}

output "access_keys" {
  description = "Access key IDs for users"
  value = {
    for name, key in aws_iam_access_key.access_keys :
    name => {
      id     = key.id
      secret = key.secret
    }
  }
  sensitive = true
}

output "passwords" {
  description = "Initial passwords for users with login profiles"
  value = {
    for name, profile in aws_iam_user_login_profile.login_profiles :
    name => profile.password
  }
  sensitive = true
}