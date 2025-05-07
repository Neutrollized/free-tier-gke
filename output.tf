output "_connection_string" {
  value       = var.enable_private_endpoint && !var.enable_dns_endpoint ? "gcloud container clusters get-credentials ${var.gke_cluster_name} --location ${var.zone} --project ${var.project_id} --internal-ip" : (var.enable_dns_endpoint ? "gcloud container clusters get-credentials ${var.gke_cluster_name} --location ${var.zone} --project ${var.project_id} --dns-endpoint" : "gcloud container clusters get-credentials ${var.gke_cluster_name} --location ${var.zone} --project ${var.project_id}")
  description = "CLI command used to obtain Kubernetes credentials for the GKE cluster."
}

output "dns_endpoint" {
  value       = var.enable_dns_endpoint ? google_container_cluster.primary.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint : "DNS-based endpoint not enabled"
  description = "GKE DNS endpoint"
}

output "create_iap_tunnel" {
  value       = var.enable_private_endpoint && !var.enable_dns_endpoint ? "gcloud compute ssh ${google_compute_instance.iap-proxy[0].name} --location ${var.zone} --project ${var.project_id} -- -L 8888:localhost:8888 -N -q -f" : "Private IP-based endpoint not enabled"
  description = "CLI command use to enable IAP tunnel to GCE VM instance to forward kubectl commands."
}
