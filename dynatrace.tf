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
# Set the environment apiUrl via TF_VAR_dynatrace_api_url (see variable below).

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

# DynaKube custom resource. Rendered from Terraform because its only environment
# specific input — apiUrl — comes from a TF variable (set once after you
# register), while the tokens come from the ESO-synced "dynakube" Secret. The
# Dynatrace Operator itself is installed via a GitOps Argo Application.
#
# Created only when dynatrace_api_url is set, so the platform applies cleanly
# before you have a Dynatrace environment.
resource "kubectl_manifest" "dynakube" {
  count = var.dynatrace_api_url != "" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "dynatrace.com/v1beta3"
    kind       = "DynaKube"
    metadata = {
      name      = "dynakube"
      namespace = "dynatrace"
    }
    spec = {
      apiUrl = var.dynatrace_api_url
      # Tokens come from the ESO-managed Secret of the same name.
      tokens = "dynakube"
      # Cloud-native full-stack: OneAgent (auto-instrumentation / APM, JVM deep
      # dive) + an ActiveGate for Kubernetes API monitoring and metrics ingest.
      oneAgent = {
        cloudNativeFullStack = {}
      }
      activeGate = {
        capabilities = [
          "routing",
          "kubernetes-monitoring",
          "metrics-ingest",
          "dynatrace-api",
        ]
        resources = {
          requests = {
            cpu    = "100m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }
      }
    }
  })

  depends_on = [
    kubectl_manifest.dynatrace_external_secret,
  ]
}
