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
    type     = base64encode("git")
    url      = base64encode(var.gitops_repo_url)
    username = base64encode("git")
    password = base64encode(var.github_token_argocd)
  }

  depends_on = [helm_release.argocd]
}
