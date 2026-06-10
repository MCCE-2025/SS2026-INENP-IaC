resource "helm_release" "argocd_root_app" {
  name      = "argocd-root-app"
  chart     = "${path.module}/charts/argocd-root-app"
  namespace = helm_release.argocd.namespace

  values = [
    yamlencode({
      gitops_repo_url        = var.gitops_repo_url
      gitops_target_revision = var.gitops_target_revision
      gitops_apps_path       = var.gitops_apps_path
      argocd_namespace       = helm_release.argocd.namespace
    })
  ]

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.gitops_repo,
  ]
}
