# GCP service account used by cert-manager's DNS-01 solver to create the ACME
# TXT challenge records in Cloud DNS. Authenticates via GKE Workload Identity
# bound to the cert-manager controller's Kubernetes ServiceAccount.

resource "google_service_account" "cert_manager_dns" {
  account_id   = "cert-manager-dns"
  display_name = "cert-manager DNS-01 solver"
}

resource "google_project_iam_member" "cert_manager_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager_dns.email}"
}

resource "google_service_account_iam_member" "cert_manager_dns_workload_identity" {
  service_account_id = google_service_account.cert_manager_dns.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[cert-manager/cert-manager]"
}

output "cert_manager_dns_service_account" {
  description = "GCP service account email to annotate on the cert-manager Kubernetes ServiceAccount for DNS-01"
  value       = google_service_account.cert_manager_dns.email
}
