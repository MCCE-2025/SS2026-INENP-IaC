output "state_bucket_name" {
  description = "GCS bucket used for Terraform remote state."
  value       = google_storage_bucket.tf_state.name
}
