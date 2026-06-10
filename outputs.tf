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
