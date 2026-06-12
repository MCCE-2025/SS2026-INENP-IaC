resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "2.6.0"

  values = [
    yamlencode({
      serviceAccount = {
        name = "external-secrets"
        annotations = {
          "iam.gke.io/gcp-service-account" = google_service_account.external_secrets.email
        }
      }
    })
  ]

  depends_on = [
    google_container_cluster.cluster,
    google_container_node_pool.node_pool,
    google_service_account_iam_member.external_secrets_workload_identity,
  ]
}

resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "gcp-secret-manager"
    }
    spec = {
      provider = {
        gcpsm = {
          projectID = var.project_id
          auth = {
            workloadIdentity = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  })

  depends_on = [helm_release.external_secrets]
}

resource "kubectl_manifest" "gitops_repo_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "gitops-repo"
      namespace = "argocd"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "gcp-secret-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "gitops-repo"
        creationPolicy = "Owner"
        template = {
          engineVersion = "v2"
          metadata = {
            labels = {
              "argocd.argoproj.io/secret-type" = "repository"
            }
          }
          data = {
            type                    = "git"
            url                     = var.gitops_repo_url
            githubAppID             = "{{ .githubAppID }}"
            githubAppInstallationID = "{{ .githubAppInstallationID }}"
            githubAppPrivateKey     = "{{ .githubAppPrivateKey }}"
          }
        }
      }
      data = [
        {
          secretKey = "githubAppPrivateKey"
          remoteRef = {
            key = google_secret_manager_secret.argocd_github_app["argocd-github-app-private-key"].secret_id
          }
        },
        {
          secretKey = "githubAppID"
          remoteRef = {
            key = google_secret_manager_secret.argocd_github_app["argocd-github-app-id"].secret_id
          }
        },
        {
          secretKey = "githubAppInstallationID"
          remoteRef = {
            key = google_secret_manager_secret.argocd_github_app["argocd-github-app-installation-id"].secret_id
          }
        },
      ]
    }
  })

  depends_on = [
    helm_release.external_secrets,
    helm_release.argocd,
    kubectl_manifest.cluster_secret_store,
  ]
}
