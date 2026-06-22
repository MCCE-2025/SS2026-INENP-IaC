resource "google_project_service" "sqladmin" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Cloud SQL uses a public IP with no authorized networks. Pods connect only via
# the Cloud SQL Auth Proxy sidecar (see backend Helm chart). Private IP would
# require google_service_networking_connection, which needs
# roles/servicenetworking.networksAdmin on the Terraform runner.
