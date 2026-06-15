resource "google_service_account" "crossplane_gar" {
  account_id   = "crossplane-gar"
  display_name = "Crossplane GCP Artifact Registry provider"
}

resource "google_project_iam_member" "crossplane_gar_artifactregistry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.crossplane_gar.email}"
}

resource "google_service_account_iam_member" "crossplane_gar_workload_identity" {
  service_account_id = google_service_account.crossplane_gar.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[crossplane-system/provider-gcp-artifact]"
}

resource "google_project_iam_member" "node_artifactregistry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
