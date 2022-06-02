output "connect_to_zonal_cluster" {
  value = "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id}"
}

output "enable_workload_identity_on_node_pool" {
  value = "gcloud container node-pools update ${var.gke_nodepool_name} --cluster ${var.gke_cluster_name} --workload-metadata=GKE_METADATA --zone ${var.zone} --project ${var.project_id}"
}
