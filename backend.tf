terraform {
  backend "gcs" {
    # bucket is intentionally omitted here: backend blocks cannot use variables.
    # It is provided at init time via partial configuration, e.g.:
    #   terraform init -backend-config="bucket=terraform-state-$(gcloud config get-value project)"
    prefix = "platform-terraform"
  }
}
