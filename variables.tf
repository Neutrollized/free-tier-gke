#-----------------------
# provider variables
#-----------------------
variable "project_id" {}

variable "credentials_file_path" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

#------------------------------------------------
# VPC_native cluster networking
# https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips#cluster_sizing_secondary_range_svcs
#------------------------------------------------

variable "primary_vm_cidr" {
  description = "Primary CIDR for nodes"
  default     = "10.0.0.0/24"
}

variable "secondary_cluster_cidr" {
  description = "Secondary CIDR for pods"
  default     = "172.16.0.0/16"
}

variable "secondary_service_cidr" {
  description = "Secondary CIDR for services.  If not set, it will use the secondary_pod_cidr to allocate IPs for services as well."
  default     = "172.20.0.0/16"
}

#-----------------------------
# GKE Cluster
#-----------------------------

variable "gke_cluster_name" {}

variable "regional" {
  description = "Is this cluster regional or zonal? Regional clusters aren't covered by Google's Always Free tier."
  default     = "false"
}

variable "node_locations" {
  type    = list(string)
  default = []
}

variable "enable_shielded_nodes" {
  description = "Shielded GKE nodes provide strong cryptographic identity for nodes joining a cluster.  Will be default with version 1.18+"
  default     = "true"
}

variable "networking_mode" {
  description = "Determines whether alias IPs or routes are used for pod IPs in the cluster.  ip_allocation_policy block needs to be defined if using VPC_NATIVE.  Accepted values are VPC_NATIVE or ROUTES."
  default     = "VPC_NATIVE"
}

variable "cluster_secondary_range_name" {
  default = ""
}

variable "services_secondary_range_name" {
  default = ""
}

variable "channel" {
  description = "The channel to get the k8s release from. Accepted values are UNSPECIFIED, RAPID, REGULAR and STABLE"
  default     = "UNSPECIFIED"
}

variable "http_lb_disabled" {
  description = "If enabled, a controller will be installed to coordinate applying load balancing configuration changes to your GCP project."
  default     = "false"
}

variable "istio_disabled" {
  description = "If enabled, the Istio components will be installed in your cluster."
  default     = "true"
}

#-----------------------------
# GKE Node Pool
#-----------------------------

variable "machine_type" {
  default = "e2-small"
}

variable "disk_size_gb" {
  description = "The default disk size the nodes are given.  100G is probably too much for a test cluster, so you can change it if you'd like.  Don't set it too low though as disk I/O is also tied to disk size."
  default     = "100"
}

variable "min_nodes" {
  default = "1"
}

variable "max_nodes" {
  default = "3"
}

variable "auto_upgrade" {
  description = "Enables auto-upgrade of cluster.  Needs to be 'true' unless 'channel' is UNSPECIFIED"
  default     = "false"
}

