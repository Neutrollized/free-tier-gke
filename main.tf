#------------------------------------------------------
# GKE Cluster
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster.html#example-usage---with-a-separately-managed-node-pool-recommended
#------------------------------------------------------
resource "google_container_cluster" "primary" {
  provider = google-beta

  name                = var.gke_cluster_name
  location            = var.regional ? var.region : var.zone
  deletion_protection = var.deletion_protection

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

  network    = google_compute_network.k8s.id
  subnetwork = google_compute_subnetwork.k8s.id

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
  #  dynamic "private_cluster_config" {
  #for_each = var.enable_private_nodes ? [1] : []
  #content {
  #      enable_private_endpoint = var.enable_private_endpoint
  #enable_private_nodes    = var.enable_private_nodes
  # only applicable when enable_private_nodes = true
  # master_ipv4_cidr_block = var.master_ipv4_cidr_block
  #}
  # }
  dynamic "private_cluster_config" {
    for_each = var.enable_private_nodes || var.enable_private_endpoint ? [1] : []
    content {
      enable_private_endpoint = var.enable_dns_endpoint ? true : var.enable_private_endpoint
      enable_private_nodes    = var.enable_private_nodes
      # only applicable when enable_private_nodes = true
      master_ipv4_cidr_block = var.enable_dns_endpoint ? null : var.master_ipv4_cidr_block
    }
  }

  dynamic "control_plane_endpoints_config" {
    for_each = var.enable_dns_endpoint ? [1] : []
    content {
      dns_endpoint_config {
        allow_external_traffic = var.dns_endpoint_allow_ext_traffic
      }
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.enable_private_endpoint && !var.enable_dns_endpoint ? [1] : []
      content {
        cidr_block   = var.enable_private_endpoint && !var.enable_dns_endpoint ? var.iap_proxy_ip_cidr : var.master_authorized_network_cidr
        display_name = "allowed-cidr"
      }
    }
  }

  # https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2#create-cluster
  # NOTE: DPv2 has its own network policy enforcement built-in
  #       and this should be set to 'false' when DPv2 is enabled
  network_policy {
    enabled = var.network_policy_enabled
  }

  datapath_provider = var.dataplane_v2_enabled ? "ADVANCED_DATAPATH" : "DATAPATH_PROVIDER_UNSPECIFIED"

  # https://cloud.google.com/kubernetes-engine/docs/how-to/configure-cilium-network-policy
  enable_cilium_clusterwide_network_policy = var.enable_cilium_clusterwide_network_policy

  # https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-dns
  dns_config {
    cluster_dns       = var.cluster_dns
    cluster_dns_scope = var.cluster_dns_scope
  }

  gateway_api_config {
    channel = var.gateway_api_channel
  }

  release_channel {
    channel = var.release_channel
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
        enable_relay   = var.enable_dpv2_relay
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
    horizontal_pod_autoscaling {
      disabled = lookup(var.addons_config, "hpa_disabled", false)
    }

    http_load_balancing {
      disabled = lookup(var.addons_config, "http_lb_disabled", false)
    }

    gcp_filestore_csi_driver_config {
      enabled = lookup(var.addons_config, "gcp_filestore_csi_driver_enabled", false)
    }

    gcs_fuse_csi_driver_config {
      enabled = lookup(var.addons_config, "gcs_fuse_csi_driver_enabled", false)
    }

    gce_persistent_disk_csi_driver_config {
      enabled = lookup(var.addons_config, "gce_pd_csi_driver_enabled", false)
    }

    gke_backup_agent_config {
      enabled = lookup(var.addons_config, "gke_backup_agent_enabled", false)
    }

    config_connector_config {
      enabled = lookup(var.addons_config, "config_connector_enabled", false)
    }

    ray_operator_config {
      enabled = lookup(var.addons_config, "ray_operator_enabled", false)
    }
  }

  lifecycle {
    ignore_changes = [
      dns_config,
    ]
  }
}


#------------------------------------------------------
# GKE Cluster Node Pool
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool
#------------------------------------------------------
resource "random_pet" "node_pool" {
  length = 1
}

resource "google_container_node_pool" "primary" {
  provider = google-beta

  name     = random_pet.node_pool.id
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
    spot         = var.spot
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    image_type   = var.image_type

    shielded_instance_config {
      enable_secure_boot          = var.shielded_vm_enable_secure_boot
      enable_integrity_monitoring = var.shielded_vm_enable_integrity_monitoring
    }

    labels = {
      mesh_id = "proj-${var.project_id}"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    kubelet_config {
      insecure_kubelet_readonly_port_enabled = "FALSE"
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

  lifecycle {
    # nodes can be either a preemptible VM or a Spot VM, but not both
    precondition {
      condition     = !(var.preemptible && var.spot)
      error_message = "Variables 'preemptible' and 'spot' cannot both be true"
    }
    ignore_changes = [
      node_config[0].resource_labels,
    ]
  }
}
