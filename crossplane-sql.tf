resource "google_service_account" "crossplane_sql" {
  account_id   = "crossplane-sql"
  display_name = "Crossplane GCP Cloud SQL provider"
}

resource "google_project_iam_member" "crossplane_sql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.crossplane_sql.email}"

  depends_on = [google_project_service.sqladmin]
}

resource "google_service_account_iam_member" "crossplane_sql_workload_identity" {
  service_account_id = google_service_account.crossplane_sql.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[crossplane-system/provider-gcp-sql]"
}
