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

data "google_project" "current" {
  project_id = var.project_id
}

# Tenant namespaces are discovered automatically from the GitOps repo: every
# directory under tenants/ becomes a namespace that runs a backend. This means a
# new tenant needs NO change here — just add the tenants/<name> folder in GitOps
# and re-apply. `backend` is the legacy non-tenant namespace, always included.
locals {
  gitops_tenants_dir = "${path.module}/../SS2026-INENP-GitOps/tenants"

  tenant_namespaces = toset([
    for entry in fileset(local.gitops_tenants_dir, "*/namespace.yaml") :
    dirname(entry)
  ])

  backend_workload_identity_namespaces = toset(
    concat(["backend"], tolist(local.tenant_namespaces))
  )
}

# Grant each backend namespace permission to impersonate the GCP SA via Workload
# Identity. Uses the principalSet identifier scoped to the namespace, so any pod
# in that namespace using the bound KSA can mint tokens for Cloud SQL.
resource "google_service_account_iam_member" "weather_app_backend_workload_identity" {
  for_each = local.backend_workload_identity_namespaces

  service_account_id = google_service_account.weather_app_backend.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value}/weather-app-backend]"
}
