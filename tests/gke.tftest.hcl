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
    dataplane_v2_enabled = true
  }

  # Check that the cluster name is correct
  assert {
    condition     = google_container_cluster.primary.name == run.setup_tests.cluster_name
    error_message = "Invalid GKE cluster name"
  }

  # Check that Dataplane V2 is enabled correctly
  assert {
    condition     = google_container_cluster.primary.datapath_provider == "ADVANCED_DATAPATH"
    error_message = "Invalid dataplane"
  }
}
