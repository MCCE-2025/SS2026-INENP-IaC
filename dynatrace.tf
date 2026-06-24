# Dynatrace tokens, wired like every other platform secret: the secret CONTAINERS
# are created here, but the VALUES are added by you once (out of band) after you
# register on Dynatrace and generate the tokens — so the tokens never land in
# Terraform state or Git. ESO then syncs them into the cluster as the "dynakube"
# Secret that the Dynatrace Operator expects.
#
# After `terraform apply`, add the two token values (see README/commands below):
#
#   printf '<OPERATOR_API_TOKEN>'  | gcloud secrets versions add dynatrace-api-token \
#     --project=<project> --data-file=-
#   printf '<DATA_INGEST_TOKEN>'   | gcloud secrets versions add dynatrace-data-ingest-token \
#     --project=<project> --data-file=-
#
# The environment apiUrl is set in the GitOps DynaKube manifest
# (platform/dynatrace/dynakube.yaml), not here (apiUrl is not a secret).

resource "google_secret_manager_secret" "dynatrace_api_token" {
  secret_id = "dynatrace-api-token"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret" "dynatrace_data_ingest_token" {
  secret_id = "dynatrace-data-ingest-token"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# The dynatrace namespace must exist before ESO can write the Secret into it.
# Argo also has CreateNamespace=true; this just makes ordering deterministic.
resource "kubernetes_namespace" "dynatrace" {
  metadata {
    name = "dynatrace"
  }
}

# ESO materializes the Operator-expected Secret ("dynakube") with the apiToken and
# dataIngestToken keys from Secret Manager. The DynaKube CR references it via
# spec.tokens (defaults to the DynaKube name, which we set to "dynakube").
resource "kubectl_manifest" "dynatrace_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "dynakube"
      namespace = "dynatrace"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "gcp-secret-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "dynakube"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "apiToken"
          remoteRef = {
            key = google_secret_manager_secret.dynatrace_api_token.secret_id
          }
        },
        {
          secretKey = "dataIngestToken"
          remoteRef = {
            key = google_secret_manager_secret.dynatrace_data_ingest_token.secret_id
          }
        },
      ]
    }
  })

  depends_on = [
    helm_release.external_secrets,
    kubectl_manifest.cluster_secret_store,
    kubernetes_namespace.dynatrace,
  ]
}

# NOTE: The DynaKube custom resource is NOT created here. It depends on the
# DynaKube CRD, which is installed by the Dynatrace Operator via its GitOps Argo
# Application — so creating the CR from Terraform in the same run fails with
# "DynaKube isn't valid for cluster" (CRD not yet present). Instead, the DynaKube
# CR lives in the GitOps repo (platform/dynatrace/dynakube.yaml) with sync-waves,
# so Argo applies the operator (CRD) first and the CR after. Terraform only owns
# the tokens (Secret Manager) and the ESO ExternalSecret above. Set the apiUrl in
# that GitOps manifest.
