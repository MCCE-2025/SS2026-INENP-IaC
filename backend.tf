terraform {
  backend "gcs" {
    bucket = "terraform-state-sonorous-stone-498307-u2"
    prefix = "platform-terraform"
  }
}
