locals {
  github_backend_name = split("/", var.github_backend_repo)[1]
}

resource "github_actions_variable" "gcp_project_id" {
  repository    = local.github_backend_name
  variable_name = "GCP_PROJECT_ID"
  value         = var.project_id
}

resource "github_actions_variable" "gar_location" {
  repository    = local.github_backend_name
  variable_name = "GAR_LOCATION"
  value         = google_artifact_registry_repository.platform_containers.location
}

resource "github_actions_variable" "gar_repository" {
  repository    = local.github_backend_name
  variable_name = "GAR_REPOSITORY"
  value         = google_artifact_registry_repository.platform_containers.repository_id
}

resource "github_actions_variable" "gcp_wif_provider" {
  repository    = local.github_backend_name
  variable_name = "GCP_WIF_PROVIDER"
  value         = google_iam_workload_identity_pool_provider.github.name
}

resource "github_actions_variable" "gcp_service_account" {
  repository    = local.github_backend_name
  variable_name = "GCP_SERVICE_ACCOUNT"
  value         = google_service_account.github_actions_deployer.email
}
