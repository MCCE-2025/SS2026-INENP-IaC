data "google_project" "this" {}

data "google_dns_managed_zone" "external_dns" {
  name = var.dns_managed_zone_name
}

locals {
  external_dns_principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/${var.external_dns_namespace}/sa/${var.external_dns_ksa}"
}

resource "google_project_iam_member" "external_dns_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = local.external_dns_principal
}
