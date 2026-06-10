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
