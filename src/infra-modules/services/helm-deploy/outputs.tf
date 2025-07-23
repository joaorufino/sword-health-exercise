# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.main.name
}

output "release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.main.namespace
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.main.status
}

output "release_version" {
  description = "Version of the deployed chart"
  value       = helm_release.main.version
}

output "release_revision" {
  description = "Revision number of the release"
  value       = helm_release.main.metadata[0].revision
}

output "service_account_name" {
  description = "Name of the created service account"
  value       = var.create_service_account ? kubernetes_service_account.main[0].metadata[0].name : null
}

output "namespace_created" {
  description = "Whether a namespace was created"
  value       = length(kubernetes_namespace.main) > 0
}