data "google_netblock_ip_ranges" "health-checkers" {
  range_type = "health-checkers"
}

data "google_netblock_ip_ranges" "iap-forwarders" {
  range_type = "iap-forwarders"
}
