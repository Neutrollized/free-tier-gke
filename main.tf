# https://www.terraform.io/docs/providers/google/r/container_cluster.html#example-usage-with-a-separately-managed-node-pool-recommended-

resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = var.gke_cluster_name
  location = var.regional ? var.region : var.zone

  # Can be single or multi-zone, as
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_locations
  node_locations = var.node_locations

  enable_shielded_nodes = var.enable_shielded_nodes

  network    = google_compute_network.k8s_vpc.id
  subnetwork = google_compute_subnetwork.k8s_subnet.id

  # ip_allocation_policy left empty here to let GCP pick
  # otherwise you will have to define your own secondary CIDR ranges
  # which I will probably look to add at a later date
  networking_mode = var.networking_mode
  ip_allocation_policy {}

  private_cluster_config {
    enable_private_endpoint = var.enable_private_endpoint
    enable_private_nodes    = var.enable_private_nodes
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # not recommended for prod, obvs
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "allow-all"
    }
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = var.channel
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  addons_config {
    http_load_balancing {
      disabled = var.http_lb_disabled
    }

    istio_config {
      disabled = var.istio_disabled
    }
  }
}


resource "google_container_node_pool" "primary_preemptible_nodes" {
  name     = "preempt-pool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  initial_node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  management {
    auto_repair  = true
    auto_upgrade = var.auto_upgrade
  }

  node_config {
    preemptible  = true
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
