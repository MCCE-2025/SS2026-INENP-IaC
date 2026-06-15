# Workload Identity Federation for GitHub Actions to push images to Artifact
# Registry without any long-lived service account keys. The GitHub OIDC token is
# exchanged for short-lived GCP credentials, scoped to the backend repository.

resource "google_service_account" "ci_image_push" {
  account_id   = "ci-image-push"
  display_name = "GitHub Actions image push to Artifact Registry"
}

resource "google_project_iam_member" "ci_image_push_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.ci_image_push.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "OIDC federation for GitHub Actions workflows"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Restrict which tokens this provider will accept to the backend repository,
  # preventing any other GitHub repo from impersonating the CI service account.
  attribute_condition = "assertion.repository == '${var.backend_github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "ci_image_push_wif" {
  service_account_id = google_service_account.ci_image_push.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.backend_github_repo}"
}

output "ci_wif_provider" {
  description = "Full resource name to pass as workload_identity_provider in the GitHub Actions google-github-auth step"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "ci_image_push_service_account" {
  description = "Service account email to pass as service_account in the GitHub Actions google-github-auth step"
  value       = google_service_account.ci_image_push.email
}
