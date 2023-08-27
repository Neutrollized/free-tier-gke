output "connection_string" {
  value = var.enable_private_endpoint ? "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id} --internal-ip" : "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id}"
}

output "create_iap_tunnel" {
  value = var.enable_private_endpoint ? "gcloud compute ssh ${google_compute_instance.iap-proxy[0].name} --zone ${var.zone} --project ${var.project_id} -- -L 8888:localhost:8888 -N -q -f" : "N/A - private cluster not enabled"
}

output "enable_workload_identity_on_node_pool" {
  value = var.workload_metadata_enabled ? "N/A - Workload Identity already enabled" : "gcloud container node-pools update ${var.gke_nodepool_name} --cluster ${var.gke_cluster_name} --workload-metadata=GKE_METADATA --zone ${var.zone} --project ${var.project_id}"
}

output "enable_disable_hubble" {
  value = var.dataplane_v2_enabled && var.enable_dpv2_hubble ? "Currently enabled. To disable: gcloud container clusters update ${var.gke_cluster_name} --dataplane-v2-observability-mode=DISABLED --zone ${var.zone} --project ${var.project_id}" : "Currently disabled. To enable: gcloud container clusters update ${var.gke_cluster_name} --dataplane-v2-observability-mode=INTERNAL_VPC_LB --zone ${var.zone} --project ${var.project_id}"
}
