# GCP KMS auto-unseal for OpenBao.
#
# Instead of Shamir unseal keys that must be entered by hand after every restart,
# OpenBao uses a Cloud KMS key to seal/unseal itself automatically. The KMS key
# material stays in GCP (never in Terraform state); Terraform only creates the key
# and the IAM/Workload Identity wiring the OpenBao pod needs to call KMS.
#
# Note: `bao operator init` is still a ONE-TIME manual step (it returns recovery
# keys + the root token, which deliberately must not flow through Terraform). After
# that first init, OpenBao auto-unseals on every restart with no manual action.

resource "google_project_service" "cloudkms" {
  project            = var.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_kms_key_ring" "openbao" {
  name     = "openbao"
  location = var.region

  depends_on = [google_project_service.cloudkms]
}

resource "google_kms_crypto_key" "openbao_unseal" {
  name     = "openbao-unseal"
  key_ring = google_kms_key_ring.openbao.id
  purpose  = "ENCRYPT_DECRYPT"

  # Don't let `terraform destroy` remove the key that protects the seal — losing
  # it makes the OpenBao data unrecoverable.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "openbao" {
  account_id   = "openbao-unseal"
  display_name = "OpenBao auto-unseal (Cloud KMS)"
}

# Only encrypt/decrypt on the single unseal key — least privilege, not project-wide.
resource "google_kms_crypto_key_iam_member" "openbao_unseal" {
  crypto_key_id = google_kms_crypto_key.openbao_unseal.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.openbao.email}"
}

# Let the OpenBao server pod (KSA openbao/openbao) impersonate the GCP SA via
# Workload Identity, so it can call KMS without a static key file.
resource "google_service_account_iam_member" "openbao_workload_identity" {
  service_account_id = google_service_account.openbao.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.openbao_namespace}/${var.openbao_ksa}]"
}

output "openbao_kms_key" {
  description = "Cloud KMS crypto key used for OpenBao auto-unseal (referenced by the OpenBao Helm values seal stanza)."
  value       = google_kms_crypto_key.openbao_unseal.id
}

output "openbao_gcp_service_account" {
  description = "GCP service account email the OpenBao KSA must be annotated with for Workload Identity."
  value       = google_service_account.openbao.email
}
