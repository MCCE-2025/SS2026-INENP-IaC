resource "google_project_service" "secretmanager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

locals {
  argocd_github_app_secret_ids = [
    "argocd-github-app-private-key",
    "argocd-github-app-id",
    "argocd-github-app-installation-id",
  ]
}

resource "google_secret_manager_secret" "argocd_github_app" {
  for_each  = toset(local.argocd_github_app_secret_ids)
  secret_id = each.value
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_service_account" "external_secrets" {
  account_id   = "external-secrets"
  display_name = "External Secrets Operator (GCP Secret Manager access)"
}

resource "google_project_iam_member" "external_secrets_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets.email}"

  depends_on = [
    google_project_service.secretmanager,
    google_service_account.external_secrets,
  ]
}

resource "google_service_account_iam_member" "external_secrets_workload_identity" {
  service_account_id = google_service_account.external_secrets.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets]"
}
