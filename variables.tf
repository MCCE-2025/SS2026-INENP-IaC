variable "project_id" {
  description = "Google Cloud project ID (supply via TF_VAR_project_id, e.g. export TF_VAR_project_id=$(gcloud config get-value project))"
  type        = string
}
variable "region" {
  description = "region"
  type        = string
  default     = "europe-west3"
}
variable "zone" {
  description = "zone"
  type        = string
  default     = "europe-west3-a"
}

variable "ha_node_zones" {
  description = "Zones for node pool spread (min 2 for minimal HA across failure domains)"
  type        = list(string)
  default     = ["europe-west3-a", "europe-west3-b"]
}

variable "gitops_repo_url" {
  description = "GitOps repository URL for Argo CD"
  type        = string
  default     = "https://github.com/MCCE-2025/SS2026-INENP-GitOps"
}

variable "gitops_apps_path" {
  description = "Path in the GitOps repo where platform and tenant Application manifests live"
  type        = string
  default     = "apps"
}

variable "gitops_target_revision" {
  description = "Git branch, tag, or commit for the GitOps repo"
  type        = string
  default     = "HEAD"
}

variable "github_app_id" {
  description = "GitHub App ID used by Argo CD to access the GitOps repository"
  type        = string
}

variable "github_app_installation_id" {
  description = "Installation ID of the GitHub App on the GitOps repository"
  type        = string
}

variable "github_app_private_key" {
  description = "Private key (PEM content) of the GitHub App (e.g. export TF_VAR_github_app_private_key=\"$(cat argocd-app.private-key.pem)\")"
  type        = string
  sensitive   = true
}
