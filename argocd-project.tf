resource "kubernetes_manifest" "argocd_project_platform" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "platform"
      namespace = helm_release.argocd.namespace
    }
    spec = {
      description = "Platform infrastructure components (Crossplane, ExternalDNS, etc.)"
      sourceRepos = [
        var.gitops_repo_url,
        "https://charts.crossplane.io/stable",
        "https://kubernetes-sigs.github.io/external-dns/",
        "https://charts.jetstack.io",
        "https://kyverno.github.io/kyverno/",
        "https://kubernetes.github.io/ingress-nginx",
        # OpenBao (secret manager) Helm chart repository.
        "https://openbao.github.io/openbao-helm",
        # OCI Helm charts (Kargo, Dynatrace). Argo CD matches sourceRepos against the
        # Application's repoURL, which for an OCI Helm source is written WITHOUT the
        # "oci://" scheme. We list BOTH forms so the allowlist matches regardless of
        # how Argo normalizes the scheme across versions.
        # Kargo (code promotion) — OCI Helm chart on GHCR (chart = "kargo").
        "ghcr.io/akuity/kargo-charts",
        "oci://ghcr.io/akuity/kargo-charts",
        # Dynatrace Operator (observability/APM) — OCI Helm chart on public ECR.
        "public.ecr.aws/dynatrace",
        "oci://public.ecr.aws/dynatrace",
      ]
      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = "*"
        },
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        },
      ]
      namespaceResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        },
      ]
    }
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "argocd_project_apps" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "apps"
      namespace = helm_release.argocd.namespace
    }
    spec = {
      description = "Business applications deployed from separate app repositories"
      sourceRepos = [
        var.gitops_repo_url,
        var.backend_repo_url,
        var.frontend_repo_url,
      ]
      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = "*"
        },
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        },
      ]
      namespaceResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        },
      ]
    }
  }

  depends_on = [helm_release.argocd]
}
