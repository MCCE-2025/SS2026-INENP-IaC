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
  description = "Artifact Registry location; set as GAR_LOCATION in the backend repo GitHub Actions variables"
}

output "artifact_registry_repository" {
  value       = google_artifact_registry_repository.platform_containers.repository_id
  description = "Artifact Registry repository ID; set as GAR_REPOSITORY in the backend repo GitHub Actions variables"
}

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "Full WIF provider resource name; set as GCP_WIF_PROVIDER in the backend repo GitHub Actions variables"
}

output "github_actions_service_account" {
  value       = google_service_account.github_actions_deployer.email
  description = "Deployer service account email; set as GCP_SERVICE_ACCOUNT in the backend repo GitHub Actions variables"
}
