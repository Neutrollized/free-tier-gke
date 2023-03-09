#-----------------------
# provider variables
#-----------------------
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region to deploy GCP resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone to deploy GCP resources"
  type        = string
  default     = "us-central1-c"
}


#------------------------------------------------
# VPC_native cluster networking
# https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips
#------------------------------------------------

variable "primary_ip_cidr" {
  description = "Primary CIDR for nodes.  /24 will provide 256 node addresses."
  type        = string
  default     = "192.168.0.0/24"
}

variable "max_pods_per_node" {
  description = "Max pods per node should be half of the number of node IP addresses, up to a max of 110"
  type        = number
  default     = 110
}

variable "cluster_ipv4_cidr_block" {
  description = "Secondary CIDR for pods.  /24 node IPs will allow max 252 nodes * 256 pod IPs = 64,512 total IPs, so pod CIDR needs to be > than that so needs to be /16 "
  type        = string
  default     = "10.0.0.0/16"
}

variable "services_ipv4_cidr_block" {
  description = "Secondary CIDR for services.  /20 will provide 4k service IPs."
  type        = string
  default     = "10.1.0.0/20"
}

variable "proxy_only_ip_cidr" {
  description = "CIDR for proxy-only subnet to be used by internal HTTP(s) load balancers."
  type        = string
  default     = "192.168.254.0/23"
}

variable "psc_ip_cidr" {
  description = "CIDR for Private Service Connect subnet. In terms of sizing, you will need 1 IP for every 63 consumer VMs."
  type        = string
  default     = "192.168.253.0/26"
}

variable "enable_cloud_nat_logging" {
  description = "Enable logging for Cloud NAT."
  type        = bool
  default     = false
}


#-----------------------------
# IAM
#-----------------------------

variable "iam_roles_list" {
  description = "List of IAM roles to be assigned to GKE service account"
  type        = list(string)
  default = [
    "roles/container.nodeServiceAccount",
  ]
}

variable "wi_iam_roles_list" {
  description = "List of IAM roles to be assigned to Workload Identity service account"
  type        = list(string)
  default = [
    "roles/clouddebugger.agent",
    "roles/cloudprofiler.agent",
    "roles/cloudtrace.agent",
    "roles/monitoring.metricWriter",
  ]
}


#-------------------------------
# Private GKE Cluster settings
#-------------------------------

variable "enable_private_endpoint" {
  description = "When true public access to cluster (master) endpoint is disabled.  When false, it can be accessed both publicly and privately."
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Nodes only have private IPs and communicate to master via private networking."
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "CIDR of the master network.  Range must not overlap with any other ranges in use within the cluster's network.  Left blank for a public GKE endpoint but needs to be specified if provisioning a private GKE endpoint."
  type        = string
  default     = ""
}

variable "iap_proxy_ip_cidr" {
  description = "CIDR of subnet for IAP proxy VM.  Should make this subnet as small as possible (i.e. /29)"
  type        = string
  default     = "192.168.100.0/29"
}


#-----------------------------
# GKE Cluster
#-----------------------------

variable "gke_cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "regional" {
  description = "Is this cluster regional or zonal? Regional clusters aren't covered by Google's Always Free tier."
  type        = bool
  default     = false
}

variable "node_locations" {
  description = "List of zones in which the cluster's nodes are located. For zonal cluster, this can be omitted."
  type        = list(string)
  default     = []
}

variable "enable_shielded_nodes" {
  description = "Shielded GKE nodes provide strong cryptographic identity for nodes joining a cluster.  Will be default with version 1.18+"
  type        = bool
  default     = true
}

variable "enable_tpu" {
  description = "Whether to enable Cloud TPU resources in this cluster.  TPUs are Tensor Processing Units used for machine learning."
  type        = bool
  default     = false
}

variable "networking_mode" {
  description = "Determines whether alias IPs or routes are used for pod IPs in the cluster.  ip_allocation_policy block needs to be defined if using VPC_NATIVE.  Accepted values are VPC_NATIVE or ROUTES."
  type        = string
  default     = "VPC_NATIVE"
}

variable "master_authorized_network_cidr" {
  description = "External networks that can access the Kubernetes cluster master through HTTPS.  The default is to allow all (not recommended for production)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "network_policy_enabled" {
  description = "If enabled, allows GKE's network policy enforcement to control communication between cluster's pods and services.  Cannot be set to true if dataplane_v2_enabled is also set to true."
  type        = bool
  default     = false
}

variable "dataplane_v2_enabled" {
  description = "If enabled, it uses a dataplane that harnesses the power of eBPF and Cilium.  Cannot be set to true if network_policy_enabled is also set to true."
  type        = bool
  default     = false
}

variable "channel" {
  description = "The channel to get the k8s release from. Accepted values are UNSPECIFIED, RAPID, REGULAR and STABLE"
  type        = string
  default     = "UNSPECIFIED"
}

variable "filestore_csi_driver_enabled" {
  description = "When enabled, allows use of Filestore instances as volumes."
  type        = bool
  default     = false
}

variable "horizontal_pod_autoscaling_disabled" {
  description = "When enabled, allows increase/decrease number of replica pods based on resource usage of existing pods."
  type        = bool
  default     = false
}

variable "http_lb_disabled" {
  description = "When enabled, a controller will be installed to coordinate applying load balancing configuration changes to your GCP project."
  type        = bool
  default     = false
}

variable "confidential_nodes_enabled" {
  description = "If enabled, enables Confidential Nodes for this cluster.  If set to true, requires N2D machine_type AND must not be a preemptible node."
  type        = bool
  default     = false
}

variable "config_connector_enabled" {
  description = "When enabled, ConfigConnector addon will be installed.  Note: this also requires Workload Identity to be enabled. Node size should also be 4vCPUs or more."
  type        = bool
  default     = false
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#binary_authorization
variable "binary_auth_enabled" {
  description = "Enable Binary Authorization."
  type        = bool
  default     = false
}

variable "enable_managed_prometheus" {
  description = "Enable Managed Prometheus."
  type        = bool
  default     = false
}


#----------------------------------------------
# GKE Cluster - Node Auto-provisioning (NAP)
#----------------------------------------------

variable "enable_cluster_autoscaling" {
  description = "Enable node auto-provisioning."
  type        = bool
  default     = false
}

variable "nap_profile" {
  description = "Profile for how the cluster autoscaler should optimize for resource utilization.  Accepted values are BALANCED and OPTIMIZE_UTILIZATION"
  type        = string
  default     = "OPTIMIZE_UTILIZATION"
}

variable "nap_max_cpu" {
  description = "Maximum number of cores in the cluster."
  type        = number
  default     = 4
}

variable "nap_max_memory" {
  description = "Maximum number of gigabytes of memory in the cluster."
  type        = number
  default     = 8
}


#-----------------------------
# GKE Node Pool
#-----------------------------

variable "gke_nodepool_name" {
  description = "Name of node pool."
  type        = string
  default     = "preempt-pool"
}

variable "machine_type" {
  description = "Machine type of nodes in node pool."
  type        = string
  default     = "e2-small"
}

variable "preemptible" {
  description = "Preemptible nodes are Compute Engine instances that last up to 24 hours and provide no availability guarantees, but are priced lower."
  type        = bool
  default     = true
}

variable "disk_size_gb" {
  description = "The default disk size the nodes are given.  100G is probably too much for a test cluster, so you can change it if you'd like.  Don't set it too low though as disk I/O is also tied to disk size."
  type        = number
  default     = 100
}

variable "image_type" {
  description = "Node/OS image used for each node."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "initial_node_count" {
  description = "The initial number of nodes in the pool.  For regional or multi-zonal clusters, this is the number of nodes PER zone."
  type        = number
  default     = 1
}

variable "min_nodes" {
  description = "Min number of nodes per zone in node pool"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Max number of nodes per zone in node pool"
  type        = number
  default     = 3
}

variable "auto_upgrade" {
  description = "Enables auto-upgrade of cluster.  Needs to be 'true' unless 'channel' is UNSPECIFIED"
  type        = bool
  default     = false
}

variable "oauth_scopes" {
  description = "OAuth scopes of the node. Full list can be found at https://developers.google.com/identity/protocols/oauth2/scopes"
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/trace.append",
  ]
}

variable "taint" {
  description = "Used to specify node taints (if any). List of maps whose values are strings."
  type        = list(map(string))
  default = [
    #    {
    #      key    = "node.cilium.io/agent-not-ready"
    #      value  = "true"
    #      effect = "NO_SCHEDULE"
    #    }
  ]
}

# https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#option_2_node_pool_modification
variable "workload_metadata_enabled" {
  description = "Even though Workload Identity may be enabled at the cluster level, it can still be disabled at the node pool level"
  type        = bool
  default     = true
}
