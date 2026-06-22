# AVWX API token for the backend's METAR / nearest-airport calls. The secret
# CONTAINER is managed here, but the VALUE is set manually (out of band) so the
# token never lands in Terraform state or Git. After apply, add a version:
#
#   printf 'Token <your-avwx-token>' | gcloud secrets versions add avwx-api-key \
#     --project=<project> --data-file=-
#
# Note: the value must include the "Token " prefix, because the backend sends it
# verbatim as the Authorization header.
resource "google_secret_manager_secret" "avwx_api_key" {
  secret_id = "avwx-api-key"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}
