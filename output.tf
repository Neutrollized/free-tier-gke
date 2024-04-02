output "connection_string" {
  value       = var.enable_private_endpoint ? "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id} --internal-ip" : "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id}"
  description = "CLI command used to obtain Kubernetes credentials for the GKE cluster."
}

output "create_iap_tunnel" {
  value       = var.enable_private_endpoint ? "gcloud compute ssh ${google_compute_instance.iap-proxy[0].name} --zone ${var.zone} --project ${var.project_id} -- -L 8888:localhost:8888 -N -q -f" : "N/A - private cluster not enabled"
  description = "CLI command use to enable IAP tunnel to GCE VM instance to forward kubectl commands."
}

output "enable_workload_identity_on_node_pool" {
  value       = var.workload_metadata_enabled ? "N/A - Workload Identity already enabled" : "gcloud container node-pools update ${var.gke_nodepool_name} --cluster ${var.gke_cluster_name} --workload-metadata=GKE_METADATA --zone ${var.zone} --project ${var.project_id}"
  description = "CLI command used to enable Workload Identity on the GKE cluster (if not enabled at deploy time)."
}

output "enable_disable_hubble" {
  value       = var.dataplane_v2_enabled && var.enable_dpv2_hubble ? "Currently enabled. To disable: gcloud container clusters update ${var.gke_cluster_name} --disable-dataplane-v2-flow-observability --zone ${var.zone} --project ${var.project_id}" : "Currently disabled. To enable: gcloud container clusters update ${var.gke_cluster_name} --enable-dataplane-v2-flow-observability --zone ${var.zone} --project ${var.project_id}"
  description = "CLI command used to enable/disable Hubble via GKE Dataplane v2 observability tool add-on."
}
