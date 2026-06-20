resource "random_password" "cloud_sql_app" {
  length  = 32
  special = false
}

resource "google_secret_manager_secret" "cloud_sql_app_password" {
  secret_id = "cloud-sql-app-password"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "cloud_sql_app_password" {
  secret      = google_secret_manager_secret.cloud_sql_app_password.id
  secret_data = random_password.cloud_sql_app.result
}
