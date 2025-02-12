# Call the setup module to create a random cluster name
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}


# Apply run block to create GKE cluster
run "create_zonal_gke" {
  variables {
    gke_cluster_name     = run.setup_tests.cluster_name
    zone                 = "northamerica-northeast1-c"
    networking_mode      = "VPC_NATIVE"
    dataplane_v2_enabled = true
    spot                 = true
  }

  # Check that the cluster name is correct
  assert {
    condition     = google_container_cluster.primary.name == run.setup_tests.cluster_name
    error_message = "Invalid GKE cluster name"
  }

  # Check that cluster is zonal
  assert {
    condition     = google_container_cluster.primary.location == "northamerica-northeast1-c"
    error_message = "Invalid GKE cluster location"
  }

  # Check that cluster networking mode is VPC Native
  assert {
    condition     = google_container_cluster.primary.networking_mode == "VPC_NATIVE"
    error_message = "Invalid GKE cluster networking mode"
  }

  # Check that Dataplane V2 is enabled correctly
  assert {
    condition     = google_container_cluster.primary.datapath_provider == "ADVANCED_DATAPATH"
    error_message = "Invalid dataplane"
  }

  # Check that nodes are Spot VMs
  assert {
    condition     = google_container_node_pool.primary.node_config[0].spot == true
    error_message = "Invalid - nodes are not Spot VMs"
  }
}
