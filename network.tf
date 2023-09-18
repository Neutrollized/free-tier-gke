data "google_netblock_ip_ranges" "health-checkers" {
  range_type = "health-checkers"
}


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

  # settings for VPC Flow Logs, if enabled
  dynamic "log_config" {
    for_each = var.enable_intranode_visibility ? [{
      aggregation_interval = var.flow_logs_interval
      flow_sampling        = var.flow_logs_sampling
      metadata             = var.flow_logs_metadata
      filter_expr          = var.flow_logs_filter
    }] : []
    content {
      aggregation_interval = log_config.value["aggregation_interval"]
      flow_sampling        = log_config.value["flow_sampling"]
      metadata             = log_config.value["metadata"]
      filter_expr          = log_config.value["filter_expr"]
    }
  }

}

# https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways#gateway_controller_requirements
# https://cloud.google.com/load-balancing/docs/l7-internal/proxy-only-subnets
resource "google_compute_subnetwork" "proxy_only_subnet" {
  provider = google-beta

  name          = "${var.gke_cluster_name}-proxy-only-subnet"
  purpose       = "REGIONAL_MANAGED_PROXY"
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
  name        = "allow-health-check"
  network     = google_compute_network.k8s_vpc.name
  description = "Allow health checks from GCP LBs"

  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }

  # https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges
  source_ranges = data.google_netblock_ip_ranges.health-checkers.cidr_blocks_ipv4
}


#---------------------------------------------------
# Routers
# - required only if you're using private nodes
#   so the can reach the internet
#---------------------------------------------------
resource "google_compute_router" "k8s_vpc_router" {
  count   = var.enable_private_nodes ? 1 : 0
  name    = "${var.gke_cluster_name}-vpc-router"
  region  = var.region
  network = google_compute_network.k8s_vpc.id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resource/compute_router_nat
resource "google_compute_router_nat" "k8s_vpc_router_nat" {
  count                              = var.enable_private_nodes ? 1 : 0
  name                               = "${var.gke_cluster_name}-vpc-router-nat"
  router                             = google_compute_router.k8s_vpc_router[count.index].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}
