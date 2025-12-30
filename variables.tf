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
    "roles/container.defaultNodeServiceAccount",
    "roles/artifactregistry.reader",
    "roles/stackdriver.resourceMetadata.writer",
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
  default     = false
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

variable "enable_dns_endpoint" {
  description = "Enable DNS-based access to cluster"
  type        = bool
  default     = true
}

variable "dns_endpoint_allow_ext_traffic" {
  description = "Whether user traffic is allowed over this endpoint.  GCP-managed services may still use this endpoint even if this is false"
  type        = bool
  default     = true
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

variable "deletion_protection" {
  description = "Whether to allow Terraform to destroy the cluster. Unless set to 'false', 'terraform destroy' will fail."
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
  description = "Determines whether alias IPs or routes are used for pod IPs in the cluster.  ip_allocation_policy block needs to be defined if using VPC_NATIVE."
  type        = string
  default     = "VPC_NATIVE"

  validation {
    condition     = contains(["VPC_NATIVE", "ROUTES"], var.networking_mode)
    error_message = "Accepted values are VPC_NATIVE or ROUTES"
  }
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

variable "release_channel" {
  description = "The channel to get the k8s release from."
  type        = string
  default     = "UNSPECIFIED"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE", "EXTENDED"], var.release_channel)
    error_message = "Accepted values are UNSPECIFIED, RAPID, REGULAR, STABLE or EXTENDED"
  }
}

variable "cluster_dns" {
  description = "The in-cluster DNS provider to be used."
  type        = string
  default     = "PROVIDER_UNSPECIFIED"

  validation {
    condition     = contains(["PROVIDER_UNSPECIFIED", "PLATFORM_DEFAULT", "CLOUD_DNS"], var.cluster_dns)
    error_message = "Accepted values are PROVIDER_UNSPECIFIED, PLATFORM_DEFAULT or CLOUD_DNS"
  }
}

variable "cluster_dns_scope" {
  description = "The in-cluster DNS provider to be used."
  type        = string
  default     = "DNS_SCOPE_UNSPECIFIED"

  validation {
    condition     = contains(["DNS_SCOPE_UNSPECIFIED", "CLUSTER_SCOPE", "VPC_SCOPE"], var.cluster_dns_scope)
    error_message = "Accepted values are DNS_SCOPE_UNSPECIFIED, CLUSTER_SCOPE or VPC_SCOPE"
  }
}

variable "gateway_api_channel" {
  description = "Specify the Gateway API channel to use."
  type        = string
  default     = "CHANNEL_DISABLED"

  validation {
    condition     = contains(["CHANNEL_DISABLED", "CHANNEL_EXPERIMENTAL", "CHANNEL_STANDARD"], var.gateway_api_channel)
    error_message = "Accepted values are CHANNEL_DISABLED, CHANNEL_EXPERIMENTAL or CHANNEL_STANDARD"
  }
}

variable "addons_config" {
  description = "Toggles various addons for GKE"
  type        = map(bool)
  default = {
    hpa_disabled                     = false
    http_lb_disabled                 = false
    dns_cache_config_enabled         = false
    gcp_filestore_csi_driver_enabled = false
    gcs_fuse_csi_driver_enabled      = false
    gce_pd_csi_driver_enabled        = true
    gke_backup_agent_enabled         = false
    config_connector_enabled         = false
    ray_operator_enabled             = false
  }
}

variable "confidential_nodes_enabled" {
  description = "If enabled, enables Confidential Nodes for this cluster.  If set to true, requires N2D machine_type AND must not be a preemptible node."
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

variable "enable_intranode_visibility" {
  description = "If enabled, same node pod to pad traffic visible for VPC network.  Requires VPC Flow Logs for subnet to also be enabled."
  type        = bool
  default     = false
}

variable "flow_logs_interval" {
  description = "Sets aggregation interval for collecting flow logs."
  type        = string
  default     = "INTERVAL_5_SEC"
}

variable "flow_logs_sampling" {
  description = "Sets sampling rate.  0.5 means half of all collected logs are reported.  1.0 means all collected logs are reported."
  type        = number
  default     = 0.5
}

variable "flow_logs_metadata" {
  description = "Specifies whether metadata is added to VPC flow logs."
  type        = string
  default     = "INCLUDE_ALL_METADATA"
}

variable "flow_logs_filter" {
  description = "Enable/disable log filtering."
  type        = bool
  default     = true
}

variable "log_config" {
  description = "VPC Flow Log configuration.  This is set dynamically and by the flow_logs_xxx variables above.  See network.tf for more details."
  type        = list(map(string))
  default     = []
}


#----------------------------------------------
# GKE Dataplane V2 (Cilium)
#----------------------------------------------

variable "dataplane_v2_enabled" {
  description = "If enabled, it uses a dataplane that harnesses the power of eBPF and Cilium.  Cannot be set to true if network_policy_enabled is also set to true."
  type        = bool
  default     = true
}

variable "enable_cilium_clusterwide_network_policy" {
  description = "Whether CiliumClusterWideNetworkPolicy is enabled."
  type        = bool
  default     = false
}

variable "enable_dpv2_metrics" {
  description = "Enable GKE Dataplane V2 metrics"
  type        = bool
  default     = false
}

variable "enable_dpv2_relay" {
  description = "Enable GKE Dataplane V2 observability"
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
  description = "Profile for how the cluster autoscaler should optimize for resource utilization."
  type        = string
  default     = "OPTIMIZE_UTILIZATION"

  validation {
    condition     = contains(["BALANCED", "OPTIMIZE_UTILIZATION"], var.nap_profile)
    error_message = "Accepted values are BALANCED or OPTIMIZE_UTILIZATION"
  }
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

variable "machine_type" {
  description = "Machine type of nodes in node pool."
  type        = string
  default     = "e2-medium"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#guest_accelerator-1
variable "guest_accelerator_config" {
  description = "List of the type and count of GPUs attached to node. Setting the count to 0 will effectively disable the GPU."
  type = object({
    type               = optional(string, "nvidia-l4")
    count              = optional(number, 0)
    gpu_driver_version = optional(string, "LATEST")
  })
  default = {}

  validation {
    condition     = var.guest_accelerator_config.type == "nvidia-l4" #|| startswith(var.guest_accelerator_config.type, "ct")
    error_message = "You are trying to configure a GPU type that is other than NVIDIA L4, please explicitly update the validation guardrail condition to do so."
  }

  validation {
    condition     = var.guest_accelerator_config.count <= 1
    error_message = "You are trying to configure GPU count of > 1, please explicitly update the validation guardrail condition to do so."
  }

  validation {
    condition     = contains(["GPU_DRIVER_VERSION_UNSPECIFIED", "INSTALLATION_DISABLED", "DEFAULT", "LATEST"], var.guest_accelerator_config.gpu_driver_version)
    error_message = "Accepted values are GPU_DRIVER_VERSION_UNSPECIFIED, INSTALLATION_DISABLED, DISABLED or LATEST"
  }
}

variable "preemptible" {
  description = "Preemptible nodes are Compute Engine instances that last up to 24 hours and provide no availability guarantees, but are priced lower."
  type        = bool
  default     = false
}

variable "spot" {
  description = "Spot nodes are Compute Engine instances that have no fixed expiration time and like preemptible nodes can be terminated if Google Cloud needs resources for standard VMs.  Also priced lower."
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

  validation {
    condition     = contains(["COS_CONTAINERD", "UBUNTU_CONTAINERD"], var.image_type)
    error_message = "Accepted values are COS_CONTAINERD or UBUNTU_CONTAINERD"
  }
}

variable "shielded_vm_enable_secure_boot" {
  description = "Defines if the instance has Secure Boot enabled"
  type        = bool
  default     = true
}

variable "shielded_vm_enable_integrity_monitoring" {
  description = "Defines if the instance has integrity monitoring enabled"
  type        = bool
  default     = true
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

variable "location_policy" {
  description = "Algorithm used when scaling up node pool."
  type        = string
  default     = "ANY"

  validation {
    condition     = contains(["BALANCED", "ANY"], var.location_policy)
    error_message = "Accepted values are BALANCED or ANY"
  }
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
