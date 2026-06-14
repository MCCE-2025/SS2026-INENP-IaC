provider "google" {
  # set environment variable GOOGLE_APPLICATION_CREDENTIALS to the path of your service account key file (you can store it in this directory named gcp-sa-key.json which is gitignored)

  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = {
    purpose = "platform"
    env     = "classroom"
  }
}

provider "github" {
  owner = split("/", var.github_backend_repo)[0]
  # Authenticate with GITHUB_TOKEN or GH_TOKEN (Actions variables: Read and write on the backend repo).
}
