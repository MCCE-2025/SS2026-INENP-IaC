# Kargo admin credentials, managed like every other platform secret: generated
# here, stored in GCP Secret Manager, and synced into the cluster by ESO. Nothing
# is created with a manual `kubectl create secret`, and no secret value lives in
# Git or in the Argo manifests.
#
# Kargo expects a bcrypt password hash and a token signing key. Both are derived
# from random values; only the bcrypt hash + signing key are stored (never the
# plaintext admin password — see output note below if you need to log in).

resource "random_password" "kargo_admin_password" {
  length  = 32
  special = false
}

resource "random_password" "kargo_token_signing_key" {
  length  = 48
  special = false
}

# Kargo stores/compares a bcrypt hash, not the plaintext password. Terraform's
# bcrypt() produces it from the random password above.
locals {
  kargo_admin_password_hash = bcrypt(random_password.kargo_admin_password.result)
}

resource "google_secret_manager_secret" "kargo_admin_password_hash" {
  secret_id = "kargo-admin-password-hash"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "kargo_admin_password_hash" {
  secret      = google_secret_manager_secret.kargo_admin_password_hash.id
  secret_data = local.kargo_admin_password_hash

  # bcrypt() uses a random salt, so it returns a different hash on every plan.
  # Pin the first generated value so Terraform doesn't rewrite the secret (and
  # invalidate the admin login) on every apply.
  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret" "kargo_token_signing_key" {
  secret_id = "kargo-token-signing-key"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "kargo_token_signing_key" {
  secret      = google_secret_manager_secret.kargo_token_signing_key.id
  secret_data = random_password.kargo_token_signing_key.result
}

# The kargo namespace must exist before ESO can write the Secret into it. Argo
# also has CreateNamespace=true for the app, but Terraform runs first, so create
# it here too (idempotent — Argo will adopt it).
resource "kubernetes_namespace" "kargo" {
  metadata {
    name = "kargo"
  }
}

# ESO materializes the chart-expected Secret (kargo-api) in the kargo namespace
# from the two Secret Manager entries above. The Kargo Helm values reference it
# via api.secret.name.
resource "kubectl_manifest" "kargo_api_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "kargo-api"
      namespace = "kargo"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "gcp-secret-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "kargo-api"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "ADMIN_ACCOUNT_PASSWORD_HASH"
          remoteRef = {
            key = google_secret_manager_secret.kargo_admin_password_hash.secret_id
          }
        },
        {
          secretKey = "ADMIN_ACCOUNT_TOKEN_SIGNING_KEY"
          remoteRef = {
            key = google_secret_manager_secret.kargo_token_signing_key.secret_id
          }
        },
      ]
    }
  })

  depends_on = [
    helm_release.external_secrets,
    kubectl_manifest.cluster_secret_store,
    kubernetes_namespace.kargo,
  ]
}

# The plaintext admin password is sensitive; expose it only on demand
# (`terraform output -raw kargo_admin_password`) for the initial UI login.
output "kargo_admin_password" {
  description = "Kargo admin UI password (username: admin)."
  value       = random_password.kargo_admin_password.result
  sensitive   = true
}
