resource "kubernetes_secret" "gitops_repo" {
  metadata {
    name      = "gitops-repo"
    namespace = helm_release.argocd.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    type     = "git"
    url      = var.gitops_repo_url
    username = "git"
    password = var.github_token_argocd
  }

  depends_on = [helm_release.argocd]
}
