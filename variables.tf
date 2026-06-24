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
  default     = "argocd/applications"
}

variable "gitops_target_revision" {
  description = "Git branch, tag, or commit for the GitOps repo"
  type        = string
  default     = "HEAD"
}

variable "backend_repo_url" {
  description = "Backend application repository URL for Argo CD AppProject"
  type        = string
  default     = "https://github.com/MCCE-2025/SS2026-INENP-backend"
}

variable "backend_github_repo" {
  description = "GitHub owner/repo of the backend, used to scope the Workload Identity Federation binding for CI image pushes"
  type        = string
  default     = "MCCE-2025/SS2026-INENP-backend"
}

variable "frontend_repo_url" {
  description = "Frontend application repository URL for Argo CD AppProject"
  type        = string
  default     = "https://github.com/MCCE-2025/SS2026-INENP-frontend"
}

variable "frontend_github_repo" {
  description = "GitHub owner/repo of the frontend, used to scope the Workload Identity Federation binding for CI image pushes"
  type        = string
  default     = "MCCE-2025/SS2026-INENP-frontend"
}

variable "dns_managed_zone_name" {
  description = "GCP resource name of the existing Cloud DNS managed zone (gcloud managed-zones list NAME column), not the DNS domain (dnsName)"
  type        = string
}

variable "external_dns_namespace" {
  description = "Kubernetes namespace where the ExternalDNS service account lives"
  type        = string
  default     = "external-dns"
}

variable "external_dns_ksa" {
  description = "Kubernetes service account name used by ExternalDNS (must match GitOps deployment)"
  type        = string
  default     = "external-dns"
}

variable "openbao_namespace" {
  description = "Kubernetes namespace where OpenBao runs (must match the Argo Application destination)"
  type        = string
  default     = "openbao"
}

variable "openbao_ksa" {
  description = "Kubernetes service account name used by the OpenBao server pod (chart default is the release name)"
  type        = string
  default     = "openbao"
}