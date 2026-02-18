# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## [0.27.0] - 2026-02-17
### Added
- Enabling on some required Google APIs
- Private Services Access IP range for Service Networking (for services such as Cloud SQL)

## [0.26.3] - 2026-01-11
### Changed
- Expanded `examples/kuberay`, added configuration settings and new PyTorch training job example.

## [0.26.2] - 2026-01-10
### Added
- `ray_cluster_logging_config.enabled` optional subfield. Setting is tied to `var.addons_config.ray_operator_enabled`
- `ray_cluster_monitoring_config.enabled` optional subfield, but is currently set to `false` as this requires Google Cloud Managed Service for Prometheus
- `examples/kuberay`

## [0.26.1] - 2026-01-07
### Changed
- Updated Taskfiles
### Fixed
- Taskfiles' extension updated to `.yaml` rather than `.yml`

## [0.26.0] - 2025-12-30
### Added
- `var.addons_config.dns_cache_config_enabled` (defaut = `false`) used to toggle [NodeLocal DNSCache](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/), which is recommended for production clusters or large clusters with lots of Pods
- `Taskfile.yaml` to various examples
- `examples/velero` Kubernetes backup tool
### Changed
- Updated **google** and **google-beta** providers from `~> 6.11` to `~> 7.12` ([Upgrade Guide](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/version_7_upgrade))
### Removed
- Ingress NGINX example as it is being [retired on March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)

## [0.25.1] - 2025-10-18
### Changed
- Added default for `guest_accelerator_config` variable. Thank you, [jwhb](https://github.com/jwhb) for your [PR](https://github.com/Neutrollized/free-tier-gke/pull/15)
- Updated `examples/argocd` from chart version `8.3.4` to `8.6.4`
- Updated `examples/tetragon` with new Tracing Policy, `block-restricted-binaries.yaml` and `honeypot.yaml`
- Updated formatting in READMEs

## [0.25.0] - 2025-09-06
### Added
- GPU support with NVIDIA NIM example!
- New variable, `guest_accelerator_config` which contains settings (with guardrails) around the type and number of GPUs that can be deployed  
- `examples/nvidia-nim` 
### Changed
- Updated `var.addons_config.gce_pd_csi_driver_enabled = true` by default
- Updated `examples/argocd` from chart version `8.2.4` to `8.3.4`
- Updated `examples/hubble` Hubble UI from `0.13.2` to `0.13.3`

## [0.24.6] - 2025-08-06
### Fixed
- Added note for clarity in `examples/nginx-ingress` (I called it "nginx-ingress" but I'm actually using "ingress-nginx", which is the community-maintained one)

## [0.24.5] - 2025-08-01
### Changed
- Updated **hashicorp/random** provider from `3.6.3` to `3.7.2`
- Updated `examples/nginx-deployment.yaml` to set `automountServiceAccountToken: false`
- Updated `examples/argocd` from chart version `8.0.3` to `8.2.4`
- Updated `examples/tetragon` from Tetragon `v1.4.0` to `v1.4.1`

## [0.24.4] - 2025-05-18
### Changed
- Updated `examples/kyverno`
- Updated `examples/opa-gatekeeper`
- Updated `examples/prometheus`
- Updated `examples/trivy-operator`

## [0.24.3] - 2025-05-16
### Changed
- Updated `examples/argocd`
- Updated `examples/tetragon` from Tetragon `v1.3.0` to `v1.4.0`

## [0.24.2] - 2025-05-15
### Added
- `examples/argocd`
### Changed
- Updated the `--zone` flag for the GKE connection string to `--location` instead (a region or zone can be passed as the location)

## [0.24.1] - 2025-04-16
### Changed
- Updated `examples/hubble` Hubble UI from `0.13.1` to `0.13.2`
- Redid the READMEs' formatting style and fixed typos

## [0.24.0] - 2025-03-06
### Added
- New variable `enable_dns_endpoint` (default: `true`) for enabling [DNS-based endpoints](https://cloud.google.com/blog/products/containers-kubernetes/new-dns-based-endpoint-for-the-gke-control-plane)
- New variable `dns_endpoint_allow_ext_traffic` (default: `true`) for allowing user traffic is allowed over this endpoint.  Even if set to `false`, GCP-managed services may still use this endpoint
### Changed
- Updated **google** and **google-beta** providers from `~> 6.0` to `~> 6.11`
- Updated `examples/nginx-deployment.yaml`'s `securityContext` settings

## [0.23.0] - 2025-02-19
### Added
- New variables `shielded_vm_enable_secure_boot` (default: `true`) and `shielded_vm_enable_integrity_monitoring` (default: `true`) used to define some Shielded GKE Node options
### Changed
- Tightened IAM roles assigned to the GKE node service account
### Removed
- Variable `kubelet_ro_port_enabled` and hardcoded the setting to `FALSE` because there is no reason you should be enabling this.  Transition to the more secure, authenticated port `10250` if you have workloads that rely on the read-only port

## [0.22.0] - 2025-02-18
### Added
- New variable `kubelet_ro_port_enabled` (default: `FALSE`) to [disable the kubelet read-only port](https://cloud.google.com/kubernetes-engine/docs/how-to/disable-kubelet-readonly-port) as a security best practice
### Changed
- Updated IAP Proxy VM base image from `debian-11` to `debian-12`
### Fixed
- Added `enable_private_nodes = true` as a lifecycle precondition when `enable_private_endpoint` is enabled as a NAT needs to be provisioned so that the IAP Proxy VM can download and install required packages
- Updated `scripts/startup.sh` to fix tinyproxy.log creation error in the IAP Proxy VM

## [0.21.0] - 2025-02-12
### Added
- New variable `spot` (default: `true`) to provision Spot VMs for GKE nodes
- Lifecycle precondition checks
- Resource `random_pet.node_pool` to generate a random node pool name
### Changed
- Moved `random` provider declaration from `tests/setup/main.tf` to `provider.tf`
- Variable `preemptible` new default set to `false`
- Added additional IAM (logging) roles to the GKE node service account
### Deprecated 
- Variable `preempitble` in favor of `spot`.  Pricing model is the same, but [Spot VMs](https://cloud.google.com/kubernetes-engine/docs/concepts/spot-vms) have no set expiration time.  You can still choose to use preemptibles, but set `spot = false` as these settings are mutually exclusive
### Removed
- Variable `gke_nodepool_name` in favor of a more fun, [random_pet](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) as the name

## [0.20.3] - 2025-02-10
### Changed
- Updated `examples/tetragon` from Tetragon `v1.1.2` to `v1.3.0`. I previously had some Tracing Policy behavior issues since `v1.2.0` with the `block-nginx-write-index.yaml` example, which is now resolved via this [Github Issues](https://github.com/cilium/tetragon/issues/3377)

## [0.20.2] - 2025-02-08
### Changed
- Updated documentation
- Updated `machine_type` default value from `e2-small` to `e2-medium`
- Updated `examples/hubble` Hubble UI from `0.11.0` to `0.13.1`

## [0.20.1] - 2025-02-07
### Added
- `examples/prometheus`
### Changed
- Expanded `release_channel` validation values to allow `EXTENDED` (GKE provides extended support for minor versions up to 24 months)
- Updated documentation
- Updated labels in `examples/nginx-deployment.yaml` to use [Kubernetes Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)

## [0.20.0] - 2025-01-01
### Added
- New variable `gateway_api_channel` (default: `CHANNEL_DISABLED`) to specify the Gateway API channel to use
- `examples/vault-integration/vault-secrets-operator`
### Changed
- Variable `channel` renamed to `release_channel`
- Updated `examples/gke-gateway-controller`
### Removed
- `examples/traffic-director`, Anthos Service Mesh & Traffic Director has become [Cloud Service Mesh](https://cloud.google.com/service-mesh/docs/overview), so I will be phasing out these examples and replacing it with a Cloud Servie Mesh at some point

## [0.19.3] - 2024-12-03
### Added
- `examples/vault-integration/vault-injector`

## [0.19.2] - 2024-11-24
### Added
- New variable `enable_cilium_clusterwide_network_policy` (default: `false`), used for enabling [CCNP](https://cloud.google.com/kubernetes-engine/docs/how-to/configure-cilium-network-policy)
- `examples/cilium/clusterwide-network-policies`
### Changed
- Variable `dataplane_v2_enabled` now set to `true` by default

## [0.19.1] - 2024-10-21
### Fixed
- Updated `examples/tetragon` to use Tetragon `v1.1.2` instead of `v1.2.0`, due to a potential bug in the behavior of one of the policies (will need to investigate further)

## [0.19.0] - 2024-10-20
### Fixed
- Typo in `examples/tetragon/monitoring-alerts/cloud-monitoring-alerts.tf.sample` (`process_name` should be `policy_name`)
- Terraform tests GKE node pool resource reference
### Changed
- Updated **google** and **google-beta** providers from `~> 5.39` to `~> 6.0` ([Upgrade Guide](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/version_6_upgrade))
- Updated **hashicorp/random** provider from `3.5.1` to `3.6.3`
- Updated and renamed Tetragon tracing policy, `block-apt-pkg-install.yaml` to `block-pkg-managers.yaml`

## [0.18.1] - 2024-10-19
### Added
- `lifecycle` rule to ignore changes to DNS config
- `examples/resource-quotas`

## [0.18.0] - 2024-09-16
### Added
- New variable `addons_config` is a map variable for toggling various GKE add-ons (HPA, LB, CSI drivers, etc.)
- New toggles, including `ray_operator_enabled`, `gke_backup_agent_enabled`, `gce_pd_csi_driver_enabled`, and [requested](https://github.com/Neutrollized/free-tier-gke/issues/11) `gcs_fuse_csi_driver_enabled`
### Changed
- Various variables used to toggle add-ons previously have been moved to the new `addons_config` variable for better organization
- `firestore_csi_driver_enabled` renamed to `gcp_firestore_csi_driver_enabled`
- `horizontal_pod_autoscaling_disabled` renamed to `hpa_disabled`
- Updated `examples/tetragon`

## [0.17.1] - 2024-09-03
### Changed
- Updated `examples/tetragon`
- Updated `examples/kyverno`

## [0.17.0] - 2024-08-14
### Removed
- `local-exec` provisioner used to disable Hubble as enabling used to deploy a load balancer that was not managed by Terraform and would cause issues with `terraform destroy`.  Current changes no longer deploys a load balancer when Hubble is enabled
- Outputs with commands to manually update (enable/disable) GKE cluster with Workload Identity and Hubble (trying to keep the outputs to a minimum)
### Changed
- Updated **google** and **google-beta** providers from `~> 5.0` to `~> 5.39`
- Updated deprecated `advanced_datapath_observability` config settings (replaced `relay_mode` with `enable_relay`)
- Updated `examples/hubble`

## [0.16.5] - 2024-05-06
### Changed
- Updated `examples/tetragon`, added more sample tracing policies

## [0.16.4] - 2024-04-23
### Added
- `examples/trivy-operator`
### Changed
- Some `NodePort` service types in the examples were changed to `ClusterIP` 

## [0.16.3] - 2024-04-02
### Added
- Added `description` to output values
### Changed
- Added `roles/artifactregistry.reader` to GKE service account IAM roles list
- Renamed resources

## [0.16.2] - 2024-02-20
### Added
- `examples/kyverno`
### Changed
- Updated `examples/opa-gatekeeper`

## [0.16.1] - 2024-02-01
### Added
- `examples/cilium/clustermesh`
### Changed
- Moved data sources to `data.tf` for better organization
- `local-exec` provisioner command to disable Hubble `--dataplane-v2-observability-mode=DISABLED` is being deprecated and changed to `--disable-dataplane-v2-flow-observability` instead
- `examples/nginx-deployment.yaml` to include Horizontal Pod Autoscaling (HPA)
- `examples/tetragon` to include Cloud Monitoring alert example

## [0.16.0] - 2023-11-27
### Added
- New variable `deletion_protection` (default: `false`). If set to `true`, will prevent Terraform from destroying the cluster
- `dns_config` with new variables, `cluster_dns` (default: `PROVIDER_UNSPECIFIED`) and `cluster_dns_scope` (default: `DNS_SCOPE_UNSPECIFIED`).  This is for [Using Cloud DNS for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-dns). Be aware that enabling this feature has cost implications and you're subject to [Cloud DNS pricing](https://cloud.google.com/dns/pricing)
- Added additional Terraform tests
### Changed
- Updated **google** and **google-beta** providers from `~> 4.0` to `~> 5.0`

## [0.15.2] - 2023-11-06
### Added
- null resource to run `local-exec` provisioner as a workaround to handle the destruction of resources deployed for the Hubble relay (`enable_dpv2_hubble = true`), and are not under Terraform's management

## [0.15.1] - 2023-11-01
### Changed
- Updated `examples/tetragon` to celebrate the release of [Tetragon v1.0.0](https://github.com/cilium/tetragon/releases/tag/v1.0.0)!!

## [0.15.0] - 2023-10-16
### Added
- [Custom input validation rules](https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules)
- [Terrafom Tests](./tests)
- `hashicorp/random` provider `3.5.1`
### Changed
- Updated Terraform `required_version` from `~> 1.0` to `>= 1.6`
- Updated **google** provider from `>= 4.78.0` to `~> 4.0`

## [0.14.1] - 2023-09-18
### Added
- `examples/tetragon`
### Fixed
- Fixed settings [terraform.tfvars.sample](./terraform.tfvars.sample) where I had two mutually exclusive settings enabled causing an [issue](https://github.com/Neutrollized/free-tier-gke/issues/6) in deployed cluster.  Thanks, [darvelo](https://github.com/darvelo)!
### Changed
- Updated `proxy_only_subnet`'s purpose in the subnetwork from `INTERNAL_HTTPS_LOAD_BALANCER` to `REGIONAL_MANAGED_PROXY`.  This is preferred setting's name as per [Google's documentation](https://cloud.google.com/load-balancing/docs/proxy-only-subnets#proxy_only_subnet_create)).

## [0.14.0] - 2023-08-27
### Added
- New variable `enable_dpv2_metrics` (default: `false`) for enabling GKE Dataplane V2 metrics.  It is recommended this is enabled along with `enable_managed_prometheus` so that the metrics are sent to GCP Managed Prometheus.
- New variable `enable_dpv2_hubble` (default: `false`) for enabling GKE Dataplane V2 observability via [Hubble](https://github.com/cilium/hubble)
- New variable `location_policy` (default: `ANY`) for specifying the algorithm used when scaling up node pool.  ANY reduces risk of preemption in Spot and Preemptibla VMs
- `examples/hubble`
### Changed
- Updated **google** provider from `>= 4.29.0` to `>= 4.78.0` 
### Removed
- `examples/wordpress` in favor of keeping examples to be more tooling oriented

## [0.13.1] - 2023-07-30
### Fixed
- `examples/nginx-ingress` as `kubernetes.io/ingress.class` has been deprecated in favor of `spec.ingressClassName`
- `examples/nginx-ingress` changed `pathType` from `Prefix` to `ImplementationSpecific`
### Changed
- Updated various examples' READMEs
- Updated `examples/nginx-deployment.yaml`

## [0.13.0] - 2023-07-08
### Added
- `examples/secrets-store-csi-driver` 
### Changed
- Removed scenarios that would trigger recreation of GKE cluster resource.  Thank you, [whi-tw](https://github.com/whi-tw) for your [PR](https://github.com/Neutrollized/free-tier-gke/pull/3)

## [0.12.5] - 2023-05-08
### Added
- New variable `enable_intranode_visibiity` (default: `false`). If set to `true`, [VPC Flow Logs](https://cloud.google.com/vpc/docs/flow-logs) will also be enabled.
- New variable `flow_logs_interval` (default: `INTERVAL_5_SEC`) sets aggregation interval for collecting flow logs.
- New variable `flow_logs_sampling` (default: `0.5`) set sampling rate.  `0.5` means half of all collected logs are reported.
- New variable `flow_logs_metadata` (default: `INCLUDE_ALL_METADATA`) specifies whether metadata is added to VPC flow logs.
- New variable `flow_logs_filter` (default: `true`) enables/disables log filtering.

## [0.12.4] - 2023-04-13
### Changed
- Updated `examples/kaniko` to use Google Artifact Registry (GAR) instead of Google Container Registry (GCR)

## [0.12.3] - 2023-03-15
### Fixed
- Various typos and formatting inconsistencies, READMEs
### Changed
- Updated `examples/anthos-service-mesh` to include an examples with accompanying `AuthorizationPolicy`

## [0.12.2] - 2023-03-09
### Changed
- Replaced specifying GCP's special IP ranges explicitly with the data source, [`google_netblock_ip_ranges`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges)
- Replace list of roles for GKE service account with [**roles/container.nodeServiceAccount**](https://cloud.google.com/iam/docs/understanding-roles#container.nodeServiceAccount)
- Updated `examples/kaniko`

## [0.12.1] - 2023-02-28
### Changed
- Updated `examples/anthos-service-mesh` to include examples with: mTLS, ServiceEntry, fault injection and circuit breaking

## [0.12.0] - 2023-02-17
### Added
- Node label "mesh_id=proj-[PROJECT_ID]" to be used for Anthos Service Mesh
- `examples/anthos-service-mesh`
### Removed
- Variable `istio_disabled` removed as Istio on GKE has been [deprecated](https://cloud.google.com/istio/docs/istio-on-gke/overview) and is no longer supported.  Should migrate to [GKE on Anthos Service Mesh](https://cloud.google.com/istio/docs/istio-on-gke/migrate-to-anthos-service-mesh) instead.  ASM is Google's fully-supported distribution of Istio.

## [0.11.2] - 2023-02-07
### Added
- New variable `enable_managed_prometheus` (default: `false`) to disable [Managed Service for Prometheus](https://cloud.google.com/stackdriver/docs/managed-prometheus).  As of March 15, 2023 this feature will be enabled by default unless otherwise specified. 

## [0.11.1] - 2022-12-08
### Added
- `examples/opa-gatekeeper`
- `examples/falco`

## [0.11.0] - 2022-11-21
### Added
- [Node auto-provisioning](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning).  Enabling will create an set of node pools that will be managed on the user's behalf.
- Variable descriptions & type constraints
### Removed
- Removed hardcoded dependency on use of credentials file.  Users should now provide this via [environment variables](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#full-reference)

## [0.10.2] - 2022-11-12
### Fixed
- Updated `examples/gke-gateway-controller` README to reflect the new GKE version requirements and installation of the Gateway API via `gcloud` (no longer installs from kubernetes-sigs GitHub repo)

## [0.10.1] - 2022-10-15
### Added
- `examples/kaniko`
- `examples/gke-gateway-controller/optional` with steps for connecting to GKE cluster using namespace-restricted service accounts
### Changed
- Updated `examples/gke-gateway-controller` CRD version from `v0.5.0` to `v0.5.1`

## [0.10.0] - 2022-09-18
### Fixed
- Reverted fix I made in v0.9.0 regarding `linux_node_config`
- Updated conditional and requirements for Cloud NAT to also be deployed

## [0.9.0] - 2022-09-16
### Added
- New variable `config_connector_enabled` (default: `false`) to enable [Config Connector](https://cloud.google.com/config-connector/docs/overview), which will also require [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- New variable `binary_auth_enabled` (default: `false`) to enable [Binary Authorization](https://cloud.google.com/binary-authorization)
- New variable `wi_iam_roles_list` to define roles assigned to GCP SA for Workload Identity use (default roles allow will allow pods to send traces and metrics to GCP) 
- Create GCP SA for Workload Identity use based on `wi_iam_roles_list`
- `examples/workload-identity`
### Changed
- Updated **google** provider from `>= 4.10` to `>= 4.29.0` 
- Variable `workload_metadata_enabled` default changed from `false` to `true`
- Updated `examples/cilium`
### Removed
- Removed `https://www.googleapis.com/auth/cloud-platform` from the default `oauth_scopes`
### Fixed
- Added [`linux_node_config`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#linux_node_config) in GKE cluster `node_config` which would otherwise perform a cluster update in-place when running `terraform apply` if left out

## [0.8.0] - 2022-07-15
### Added
- When provisioning a GKE cluster with private nodes (`enable_private_nodes = true`), [Cloud NAT](https://cloud.google.com/nat/docs/overview) will also be deployed to provide private nodes with Internet access
- When creating a private GKE cluster (`enable_private_endpoint = true`), also creates an additional subnet where an IAP proxy VM is deployed and forwards traffic from your local machine to the private GKE cluster
- NOTE: you can have private nodes with a public GKE endpoint, but if you create a public GKE cluster/endpoint, the nodes also have to be private 
### Changed
- Updated `examples/gke-gateway-controller` CRD version from `v0.4.3` to `v0.5.0`
- Updated `examples/gke-gateway-controller` API version from `v1alpha2` to `v1beta1`

## [0.7.3] - 2022-06-30
### Changed
- Updated `examples/gke-gateway-controller` to add [HTTP traffic splitting](https://gateway-api.sigs.k8s.io/v1alpha2/guides/traffic-splitting/)
- Updated `examples/gke-ingress` to add notes on how to add/referenced Google-managed SSL certs to the deployment

## [0.7.2] - 2022-06-12
### Added
- New variable `filestore_csi_driver_enabled` (default: `false`)
- `examples/filestore-csi-driver`
### Changed
- Updated **google** provider from `~> 4.0` to `>= 4.10.0` 

## [0.7.1] - 2022-06-03
### Changed
- Updated `examples/gke-gateway-controller` to use [Cross-Namespace routing](https://gateway-api.sigs.k8s.io/v1alpha2/guides/multiple-ns/)
### Fixed
- Improper spacing in some `examples/gke-gateway-controller` YAMLs

## [0.7.0] - 2022-06-02
### Added
- New variable `gke_nodepool_name` (default: `preempt-pool`)
- Workload Identity Pool (enabled on cluster, but disabled on node-pool which can be enabled by setting `workload_metadata_enabled` to `true`)
### Changed
- Updated `examples/gke-gateway-controller` CRD version from `v0.3.0` to `v0.4.3`
- Updated `examples/gke-gateway-controller` API version from `v1alpha1` to `v1alpha2`

## [0.6.2] - 2022-05-17
### Added
- Apache v2 license

## [0.6.1] - 2022-05-04
### Changed
- Changed from using `google_project_iam_binding` (authoritative) to `google_project_iam_member` (additive) when assigning IAM role bindings
- Updated `apiVersion: policy/v1beta1` to `apiVersion: policy/v1` for `PodDisruptionBudget` in `examples/traffic-director/specs/02-injector.yaml`
- Updated `examples/traffic-director`

## [0.6.0] - 2022-03-06
### Added
- Custom least privilege service account for use as per [GKE hardening best practices](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#permissions) 
- New variable `iam_roles_list` for assinging roles to service account
- `cloud-platform` added to OAuth scope
### Changed
- Updated **google** and **google-beta** providers from `~> 3.0` to `~> 4.0`
- Updated `examples/gke-ingress`
- Updated `examples/nginx-ingress`

## [0.5.6] - 2022-01-09
### Added
- `examples/nginx-ingress`

## [0.5.5] - 2021-12-19
### Added
- `examples/gke-ingress`

## [0.5.4] - 2021-12-14
### Added
- Firewall rule to allow [Health Checks](https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges)
### Changed
- Updated `key: beta.kubernetes.io/arch` to `key: kubernetes.io/arch` for `NodeAffinity` in `examples/traffic-director/specs/02-injector.yaml`

## [0.5.3] - 2021-12-08
### Added
- New variable `oauth_scopes` for setting the nodes' OAuth scope
- `examples/traffic-director`

## [0.5.2] - 2021-12-01
### Added
- New [proxy-only subnet](https://cloud.google.com/load-balancing/docs/l7-internal/proxy-only-subnets) in `network.tf` to be used for internal HTTP(s) load balancers
- New [Private Service Connect subnet](https://cloud.google.com/vpc/docs/private-service-connect#psc-subnets)
- New variables `proxy_only_ip_cidr` and `psc_ip_cidr`
- `examples/gke-gateway-controller`

## [0.5.1] - 2021-11-17
### Added 
- New variable `confidential_nodes_enabled` for enabling [Confidential GKE Nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/confidential-gke-nodes) (default: `false`).  Enabling this feature requires `machine_type` to be set to N2D type AND `preemptible` to be set to `false`
- New variable `preemptible` for enabling preemptible nodes (default: `true`).  This is the setting the provides the saving (previously hardcoded as `true`)
- `terraform.tfvars.sample` file

## [0.5.0] - 2021-09-09
### Fixed 
- Having the network policy provider default to `CALICO` was unintended, so I will be adding the `network_policy_enabled` variable back in and added extra notes in the variable descriptions for anyone who wishes to play around with the settings themselves

## [0.4.0] - 2021-09-09
### Added
- New variable `image_type` for specifying [node images](https://cloud.google.com/kubernetes-engine/docs/concepts/node-images) (default: `COS_CONTAINERD`)
- New variable `horizontal_pod_autoscaling_disabled` for disabling the [horizontal pod autoscaler](https://cloud.google.com/kubernetes-engine/docs/how-to/horizontal-pod-autoscaling) (default: `false`)
- New variable `dataplane_v2_enabled`, which replaces `network_policy_enabled` in addition to making other configuration changes related to [GKE Dataplane V2 with Cilium](https://cloud.google.com/blog/products/containers-kubernetes/bringing-ebpf-and-cilium-to-google-kubernetes-engine)
### Removed
- Variable `network_policy_enabled`

## [0.3.3] - 2021-08-27
### Fixed
- Variable `initial_node_count` is now actually being referenced

## [0.3.2] - 2021-08-26
### Added
- New variable `initial_node_count` (default: `1`)
- Dynamic block for [taint](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#taint). Please note that even though the documentation is for the container cluster resource, you actually put the taint in the container node pool resource under `node_config` instead

## [0.3.1] - 2021-08-25
### Added
- New variable `network_policy_enabled` for enabling [Network Policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy#overview).  Please note the [cluster sizing requirements](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy#limitations_and_requirements) if you do enable this (default: `false`)
### Changed
- Updated **terraform** provider from `~> 0.15.0` to `~> 1.0`

## [0.3.0] - 2021-05-02
### Added
- New variables (`max_mods_per_node`, `cluster_ipv4_cidr_block` and `services_ipv4_cidr_block`)to support VPC-native cluster settings
- New variable `enable_tpu` (default: **false**) if you want to enable it within your cluster for your ML endeavours
- New variable `master_authorized_network_cidr` (default: **0.0.0.0/0**)
### Changed
- Updated for terraform provider from `~> 0.13.0` to `~> 0.15.0` along with any config stanza updates such as **require_providers**

## [0.2.0] - 2020-11-06
### Added
- Custom VPC creation to allow for a bit more customization to the cluster (namely, you can create private, VPC-native clusters now)
- Additional variables and settings (`networking_mode`, `private_cluster_config` block, etc.) to support this

## [0.1.2] - 2020-11-05
### Changed
- Updated **google** and **google-beta** providers from `~> 2.0` to `~> 3.0`
- Added a `regional` boolean variable to set the location to `var.region` if true and `var.zone` otherwise (default: `false`)

## [0.1.1] - 2020-08-23
### Changed
- Variablized some settings
- Shortened node pool name
- Elaborated on some details in README

## [0.1.0] - 2020-08-16
### Added
- Initial commit
