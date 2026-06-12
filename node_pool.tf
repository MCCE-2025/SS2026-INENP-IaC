resource "google_service_account" "service_account" {
  account_id   = "sa-${var.project_id}"
  display_name = "Service Account for the cluster"
}

resource "google_container_node_pool" "node_pool" {
  name_prefix    = "platform-"
  cluster        = google_container_cluster.cluster.name
  location       = var.region
  node_locations = var.ha_node_zones

  autoscaling {
    min_node_count  = length(var.ha_node_zones)
    max_node_count  = length(var.ha_node_zones) + 2
    location_policy = "BALANCED"
  }

  node_config {
    spot         = false
    machine_type = "e2-medium"

    boot_disk {
      disk_type = "pd-balanced"
      size_gb   = 25
    }

    service_account = google_service_account.service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      role = "worker"
    }
  }
}
