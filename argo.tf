resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "9.5.17"

  depends_on = [
    google_container_cluster.cluster,
    google_container_node_pool.node_pool,
  ]
}
