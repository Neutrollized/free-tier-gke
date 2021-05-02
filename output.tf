#output "connect_to_regional_cluster" {
#  value = "gcloud container clusters get-credentials ${var.gke_cluster_name} --region ${var.region} --project ${var.project_id}"
#}

output "connect_to_zonal_cluster" {
  value = "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id}"
}
