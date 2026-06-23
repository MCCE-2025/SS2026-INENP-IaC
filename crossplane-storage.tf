# Identity for the Crossplane GCP Storage provider. The frontend hosting bucket
# itself is provisioned by Crossplane as a custom component
# (XFrontendHosting -> GCS bucket; see GitOps platform/crossplane/frontend-hosting-*.yaml).
# Terraform only grants the GCP identity the provider uses, via Workload Identity.

resource "google_service_account" "crossplane_storage" {
  account_id   = "crossplane-storage"
  display_name = "Crossplane GCP Storage provider"
}

resource "google_project_iam_member" "crossplane_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.crossplane_storage.email}"
}

resource "google_service_account_iam_member" "crossplane_storage_workload_identity" {
  service_account_id = google_service_account.crossplane_storage.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[crossplane-system/provider-gcp-storage]"
}
