# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

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
