# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

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
### Changed 
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
