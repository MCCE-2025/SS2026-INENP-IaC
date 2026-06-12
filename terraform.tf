terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    # External Secrets CRDs (kubectl_manifest in external-secrets.tf).
    # kubernetes_manifest: it fetches CRD schemas from the cluster at plan time, but those CRDs
    # are installed in the same apply via helm_release.external_secrets (cluster may not exist yet).
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
  }
}
