output "_connection_string" {
  value       = var.enable_private_endpoint ? "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id} --internal-ip" : "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id}"
  description = "CLI command used to obtain Kubernetes credentials for the GKE cluster."
}

output "create_iap_tunnel" {
  value       = var.enable_private_endpoint ? "gcloud compute ssh ${google_compute_instance.iap-proxy[0].name} --zone ${var.zone} --project ${var.project_id} -- -L 8888:localhost:8888 -N -q -f" : "N/A - private cluster not enabled"
  description = "CLI command use to enable IAP tunnel to GCE VM instance to forward kubectl commands."
}
