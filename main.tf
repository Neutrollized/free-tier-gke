# https://www.terraform.io/docs/providers/google/r/container_cluster.html#example-usage-with-a-separately-managed-node-pool-recommended-

# workaround to destroy Hubble relay resource that is not managed by Terraform
resource "null_resource" "hubble_relay_destroy" {
  triggers = {
    project_id   = var.project_id
    cluster_name = var.gke_cluster_name
    location     = var.zone
  }

  provisioner "local-exec" {
    when    = destroy
    command = "gcloud container clusters update ${self.triggers.cluster_name} --project=${self.triggers.project_id} --location=${self.triggers.location} --dataplane-v2-observability-mode=DISABLED"
  }

  # ensure this runs before cluster destruction begins
  depends_on = [
    google_container_node_pool.primary_preemptible_nodes
  ]
}


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
  dynamic "node_config" {
    for_each = var.confidential_nodes_enabled ? [1] : []
    content {
      machine_type = var.machine_type

      labels = {
        mesh_id = "proj-${var.project_id}"
      }
    }
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = var.initial_node_count

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

  # Only applied if `enable_private_nodes` is `true`.
  dynamic "private_cluster_config" {
    for_each = var.enable_private_nodes ? [1] : []
    content {
      enable_private_endpoint = var.enable_private_endpoint
      enable_private_nodes    = var.enable_private_nodes
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.enable_private_endpoint ? var.iap_proxy_ip_cidr : var.master_authorized_network_cidr
      display_name = "allowed-cidr"
    }
  }

  # GKE Dataplane V2 is generally available as of GKE version 1.20.6-gke.700
  # https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2#create-cluster
  network_policy {
    enabled = var.network_policy_enabled
  }

  datapath_provider = var.dataplane_v2_enabled ? "ADVANCED_DATAPATH" : "DATAPATH_PROVIDER_UNSPECIFIED"


  release_channel {
    channel = var.channel
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  monitoring_config {
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }

    dynamic "advanced_datapath_observability_config" {
      for_each = var.dataplane_v2_enabled ? [1] : []
      content {
        enable_metrics = var.enable_dpv2_metrics
        relay_mode     = var.enable_dpv2_hubble ? "INTERNAL_VPC_LB" : "DISABLED"
      }
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  binary_authorization {
    evaluation_mode = var.binary_auth_enabled ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  # https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#autoscaling_profiles
  # NOTE: this creates an additional node pool
  dynamic "cluster_autoscaling" {
    for_each = var.enable_cluster_autoscaling ? [1] : []
    content {
      enabled             = var.enable_cluster_autoscaling
      autoscaling_profile = var.nap_profile

      resource_limits {
        resource_type = "cpu"
        maximum       = var.nap_max_cpu
      }

      resource_limits {
        resource_type = "memory"
        maximum       = var.nap_max_memory
      }
    }
  }

  addons_config {
    gcp_filestore_csi_driver_config {
      enabled = var.filestore_csi_driver_enabled
    }

    horizontal_pod_autoscaling {
      disabled = var.horizontal_pod_autoscaling_disabled
    }

    http_load_balancing {
      disabled = var.http_lb_disabled
    }

    config_connector_config {
      enabled = var.config_connector_enabled
    }
  }
}


resource "google_container_node_pool" "primary_preemptible_nodes" {
  name     = var.gke_nodepool_name
  location = var.regional ? var.region : var.zone
  cluster  = google_container_cluster.primary.id

  initial_node_count = var.initial_node_count
  autoscaling {
    min_node_count  = var.min_nodes
    max_node_count  = var.max_nodes
    location_policy = var.location_policy
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

    labels = {
      mesh_id = "proj-${var.project_id}"
    }

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

    # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#mode
    # https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#option_2_node_pool_modification
    workload_metadata_config {
      mode = var.workload_metadata_enabled ? "GKE_METADATA" : "GCE_METADATA"
    }

  }
}
