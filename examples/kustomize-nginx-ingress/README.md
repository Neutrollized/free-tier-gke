# NGINX Ingress

## Install Ingress Controller with Helm
- add repo:
  ```console
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update
  ```
- deploy NGINX ingress controller (this creates a TCP/UDP load balancer in GCP)
- wait until you get an external IP
  ```console
  helm install ingress-nginx ingress-nginx/ingress-nginx
  ```
- add the following snippet to `network.tf`
  ```
  resource "google_compute_firewall" "pods_and_master" {
    name        = "allow-pods-and-master-ipv4-cidrs"
    network     = google_compute_network.k8s_vpc.name
    description = "Allow pods and master to communicate with each other"

    direction = "INGRESS"

    allow {
      protocol = "all"
    }

    # https://cloud.google.com/community/tutorials/nginx-ingress-gke
    source_ranges = [var.cluster_ipv4_cidr_block, var.services_ipv4_cidr_block, var.master_ipv4_cidr_block]
  }
  ```
- request a tls cert from letsencrypt
  ```
  mkdir -p certbot/logs certbot/config
  cd certbot
  certbot certonly --work-dir . --logs-dir ./logs --config-dir ./config --manual --preferred-challenges=dns --agree-tos -d '*.example.com' -d 'example.com'
  # COMPLETE DNS CHALLENGES TO GET ISSUED CERTIFICATE
  ```
- deploy the example application
  ```console
  kustomize build . | kubectl apply -f -
  ```