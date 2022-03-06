# https://www.terraform.io/docs/providers/google/r/container_cluster.html#example-usage-with-a-separately-managed-node-pool-recommended-

resource "google_container_cluster" "primary" {
  provider = google-beta

  name     = var.gke_cluster_name
  location = var.regional ? var.region : var.zone

  # Can be single or multi-zone, as
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_locations
  node_locations = var.node_locations

  confidential_nodes {
    enabled = var.confidential_nodes_enabled
  }

  # this node_config block is for the "default pool", which we are not using as per recommendations:
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#node_config
  # however, it is required if you're going to use confidential nodes otherwise it will complain about the 
  # machine family not being set to N2D, even though is in the "google_container_node_pool" resource
  node_config {
    machine_type = var.machine_type
  }

  enable_shielded_nodes = var.enable_shielded_nodes
  enable_tpu            = var.enable_tpu

  network    = google_compute_network.k8s_vpc.id
  subnetwork = google_compute_subnetwork.k8s_subnet.id

  # ip_allocation_policy left empty here to let GCP pick
  # otherwise you will have to define your own secondary CIDR ranges
  # which I will probably look to add at a later date
  networking_mode = var.networking_mode
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.cluster_ipv4_cidr_block
    services_ipv4_cidr_block = var.services_ipv4_cidr_block
  }

  # https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr#cidr_ranges_for_clusters
  default_max_pods_per_node = var.max_pods_per_node

  private_cluster_config {
    enable_private_endpoint = var.enable_private_endpoint
    enable_private_nodes    = var.enable_private_nodes
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.master_authorized_network_cidr
      display_name = "allowed-cidr"
    }
  }

  # GKE Dataplane V2 is generally available as of GKE version 1.20.6-gke.700
  # https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2#create-cluster
  network_policy {
    enabled = var.network_policy_enabled
  }

  datapath_provider = var.dataplane_v2_enabled ? "ADVANCED_DATAPATH" : "DATAPATH_PROVIDER_UNSPECIFIED"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = var.initial_node_count

  release_channel {
    channel = var.channel
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = var.horizontal_pod_autoscaling_disabled
    }

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
  location = var.regional ? var.region : var.zone
  cluster  = google_container_cluster.primary.name

  initial_node_count = var.initial_node_count
  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = var.auto_upgrade
  }

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    image_type   = var.image_type

    metadata = {
      disable-legacy-endpoints = "true"
    }


    service_account = google_service_account.gke_sa.email
    oauth_scopes    = var.oauth_scopes

    dynamic "taint" {
      for_each = var.taint
      content {
        key    = taint.value["key"]
        value  = taint.value["value"]
        effect = taint.value["effect"]
      }
    }
  }
}
