terraform {
  backend "gcs" {
    bucket = "terraform-state-<TODO-after-bootstrap>-"
    prefix = "platfform-terraform"
  }
}
