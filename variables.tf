variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "sonorous-stone-498307-u2"
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

variable "github_token_argocd" {
  description = "GitHub PAT for Argo CD"
  type        = string
  sensitive   = true
}
