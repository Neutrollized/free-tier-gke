resource "google_compute_network" "k8s_vpc" {
  name = "${var.gke_cluster_name}-k8s-vpc"

  # defaults to true.  false = --subnet-mode custom
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "k8s_subnet" {
  name                     = "${var.gke_cluster_name}-subnet"
  ip_cidr_range            = var.primary_ip_cidr
  network                  = google_compute_network.k8s_vpc.id
  private_ip_google_access = "true"
  region                   = var.region
}


# https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways#gateway_controller_requirements
# https://cloud.google.com/load-balancing/docs/l7-internal/proxy-only-subnets
resource "google_compute_subnetwork" "proxy_only_subnet" {
  provider = google-beta

  name          = "${var.gke_cluster_name}-proxy-only-subnet"
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
  ip_cidr_range = var.proxy_only_ip_cidr
  network       = google_compute_network.k8s_vpc.id
  region        = var.region
}

# https://cloud.google.com/vpc/docs/private-service-connect#psc-subnets
resource "google_compute_subnetwork" "psc_subnet" {
  provider = google-beta

  name                     = "${var.gke_cluster_name}-psc-subnet"
  purpose                  = "PRIVATE_SERVICE_CONNECT"
  ip_cidr_range            = var.psc_ip_cidr
  network                  = google_compute_network.k8s_vpc.id
  private_ip_google_access = "true"
  region                   = var.region
}


#------------------------------
# Firewalls
#------------------------------

resource "google_compute_firewall" "lb_health_check" {
  name    = "allow-health-check"
  network = google_compute_network.k8s_vpc.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }

  # https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}
