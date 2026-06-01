resource "google_storage_bucket" "tf_state" {
  name     = "terraform-state-bucket-ss2026"
  location = var.region

  uniform_bucket_level_access = true
  versioning { enabled = true }

  force_destroy = false
}

resource "google_storage_bucket_iam_member" "tf_state_users" {
  for_each = toset(var.terraform_state_users)

  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.objectAdmin"
  member = "user:${each.value}"
}