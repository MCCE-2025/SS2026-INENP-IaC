resource "google_service_account" "weather_app_backend" {
  account_id   = "weather-app-backend"
  display_name = "Weather app backend (Cloud SQL Auth Proxy)"
}

resource "google_project_iam_member" "weather_app_backend_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.weather_app_backend.email}"

  depends_on = [google_project_service.sqladmin]
}

resource "google_service_account_iam_member" "weather_app_backend_workload_identity" {
  service_account_id = google_service_account.weather_app_backend.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[backend/weather-app-backend]"
}
