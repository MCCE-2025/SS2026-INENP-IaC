output "project_id" {
  value       = var.project_id
  description = "Project ID where the cluster is deployed"
}
output "region" {
  value       = var.region
  description = "Region where the cluster is deployed"
}

output "zone" {
  value       = var.zone
  description = "Zone where the cluster is deployed"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.cluster.name
  description = "Cluster Name"
}

output "kubernetes_cluster_gcloud_command" {
  value       = "KUBECONFIG=./gke.kubeconfig gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --region ${var.region} --project ${var.project_id}"
  description = "Command to get credentials for the cluster"
}

output "argocd_root_app" {
  value       = "root (syncs ${var.gitops_apps_path}/ from ${var.gitops_repo_url})"
  description = "Argo CD app-of-apps root Application managed by Terraform"
}

output "external_dns_principal" {
  value       = local.external_dns_principal
  description = "Workload Identity principal bound to roles/dns.admin for ExternalDNS"
}

output "external_dns_dns_name" {
  value       = data.google_dns_managed_zone.external_dns.dns_name
  description = "DNS name of the managed zone; use as ExternalDNS --domain-filter (without trailing dot)"
}

output "artifact_registry_location" {
  value       = google_artifact_registry_repository.platform_containers.location
  description = "Artifact Registry location; synced to GAR_LOCATION on the backend repo via github_actions_variable"
}

output "artifact_registry_repository" {
  value       = google_artifact_registry_repository.platform_containers.repository_id
  description = "Artifact Registry repository ID; synced to GAR_REPOSITORY on the backend repo via github_actions_variable"
}

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "Full WIF provider resource name; synced to GCP_WIF_PROVIDER on the backend repo via github_actions_variable"
}

output "github_actions_service_account" {
  value       = google_service_account.github_actions_deployer.email
  description = "Deployer service account email; synced to GCP_SERVICE_ACCOUNT on the backend repo via github_actions_variable"
}
