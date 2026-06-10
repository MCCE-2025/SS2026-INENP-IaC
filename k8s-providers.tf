data "google_client_config" "default" {}

locals {
  kubernetes = {
    host                   = "https://${google_container_cluster.cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

provider "helm" {
  kubernetes = local.kubernetes
}

provider "kubernetes" {
  host                   = local.kubernetes.host
  token                  = local.kubernetes.token
  cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
}
