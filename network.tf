resource "google_compute_network" "k8s_vpc" {
  name = "${var.gke_cluster_name}-k8s-vpc"

  //defaults to true.  false = --subnet-mode custom
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "k8s_subnet" {
  name                     = "${var.gke_cluster_name}-subnet"
  ip_cidr_range            = var.primary_ip_cidr
  network                  = google_compute_network.k8s_vpc.id
  private_ip_google_access = "true"
  region                   = var.region
  #  secondary_ip_range = [
  #    {
  #      range_name    = var.secondary_ip_range_name
  #      ip_cidr_range = var.secondary_ip_cidr
  #    }
  #  ]
}
