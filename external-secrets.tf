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

resource "kubectl_manifest" "backend_repo_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "backend-repo"
      namespace = "argocd"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "gcp-secret-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "backend-repo"
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
            url                     = var.backend_repo_url
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

data "google_secret_manager_secret_version" "argocd_github_app_id" {
  secret  = google_secret_manager_secret.argocd_github_app["argocd-github-app-id"].secret_id
  project = var.project_id
}

data "google_secret_manager_secret_version" "argocd_github_app_installation_id" {
  secret  = google_secret_manager_secret.argocd_github_app["argocd-github-app-installation-id"].secret_id
  project = var.project_id
}

resource "kubectl_manifest" "backend_ghcr_github_access_token" {
  yaml_body = yamlencode({
    apiVersion = "generators.external-secrets.io/v1alpha1"
    kind       = "GithubAccessToken"
    metadata = {
      name      = "ghcr-token"
      namespace = "backend"
    }
    spec = {
      appID     = chomp(data.google_secret_manager_secret_version.argocd_github_app_id.secret_data)
      installID = chomp(data.google_secret_manager_secret_version.argocd_github_app_installation_id.secret_data)
      permissions = {
        packages = "read"
      }
      auth = {
        privateKey = {
          secretRef = {
            name = "github-app-config"
            key  = "key"
          }
        }
      }
    }
  })

  depends_on = [
    helm_release.external_secrets,
    kubectl_manifest.cluster_secret_store,
  ]
}
