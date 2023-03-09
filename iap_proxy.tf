# the resources here are only created
# if enable_private_endpoint = "true"

data "google_netblock_ip_ranges" "iap-forwarders" {
  range_type = "iap-forwarders"
}


resource "google_compute_subnetwork" "iap_subnet" {
  count                    = var.enable_private_endpoint ? 1 : 0
  name                     = "${var.gke_cluster_name}-iap-subnet"
  ip_cidr_range            = var.iap_proxy_ip_cidr
  network                  = google_compute_network.k8s_vpc.id
  private_ip_google_access = "true"
  region                   = var.region
}

resource "google_compute_firewall" "iap_tcp_forwarding" {
  count   = var.enable_private_endpoint ? 1 : 0
  name    = "allow-ingress-from-iap"
  network = google_compute_network.k8s_vpc.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22", "8888"] # 8888 = tinyproxy port
  }

  # https://cloud.google.com/iap/docs/using-tcp-forwarding
  source_ranges = data.google_netblock_ip_ranges.iap-forwarders.cidr_blocks_ipv4
  target_tags   = ["iap"]
}


resource "google_compute_instance" "iap-proxy" {
  count        = var.enable_private_endpoint ? 1 : 0
  name         = "gke-iap-proxy"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["iap"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # because we're setting a count on the iap_subnet,
  # we now have to reference it with an index as well
  network_interface {
    network    = google_compute_network.k8s_vpc.id
    subnetwork = google_compute_subnetwork.iap_subnet[count.index].name
  }

  metadata_startup_script = file("./scripts/startup.sh")

  depends_on = [
    google_compute_router_nat.k8s_vpc_router_nat
  ]
}
