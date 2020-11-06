# Free-tier GKE Cluster
[GKE Cluster](https://www.terraform.io/docs/providers/google/r/container_cluster.html)

[GKE Container Node Pool ](https://www.terraform.io/docs/providers/google/r/container_node_pool.html)

It's not 100% free, but with my 1 node setup, I'm paying ~$4USD/mth for a fully managed Kubernetes cluster.  This works by taking advantage of Google [always free](https://cloud.google.com/free/docs/gcp-free-tier) tier which waives the management fee of one **zonal** GKE cluster, so you only have to pay for your nodes.  Combine this with using [preemptible VMs](https://cloud.google.com/compute/docs/instances/preemptible) as your nodes and you'll have some spectacular savings.

This is great if you're looking for a small k8s cluster that more closely resembles what you might see in the real world (not that [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) or [MicroK8s](https://microk8s.io/) isn't good as a learning tool -- it's just not the same).  Here, you can also scale in/out your cluster easily if you want test some features or add-ons (like service meshes!).

## GKE vs EKS vs AKS
I'm going to use a single node (2CPUs/4GB memory) Kubernetes cluster as the basis for comparison between the 3 major cloud providers.  The math is shown below, but it doesn't take an extreme couponer to figure out which is the best deal.

#### GKE
- 1 free zonal GKE cluster
- e2-medium @ $27USD/mth (or $8USD/mth for preemptible)

#### EKS
- $0.10/hr per EKS cluster @ 730hrs/mth (or $73USD/mth)
- t3.medium @ $29USD/mth

#### AKS
- [free cluster management](https://azure.microsoft.com/en-ca/pricing/details/kubernetes-service/)
- B2S @ $34USD/mth

## IMPORTANT
The key to getting the savings here is to limit the amount of nodes in your cluster (until you need it).  The 3 key settings to ensure this is `location`, `node_locations` and `node_count` (or `initial_node_count`).  

`location` specifies where to place the cluster (masters).  By specifying a zone, you have a free, zonal cluster.  If you replaced it with a region instead, it becomes a regional cluster -- ideal for a production cluster, but not part of the free tier offering.

Leaving `node_locations` blank will default your node to be in the same zone as your GKE cluster's zone.  Any zone you specify will be **in addition** to the the cluster's zone (i.e. `node_locations = ["northamerica-northeast1-a",]`), meaning your nodes will span more than one zone.  This is referred to as a multi-zone cluster.

`node_count` specifies how many nodes **per zone** rather than the total node count in your cluster.  Therefore, if you set 3 zones in `node_locations` with a `node_count` of 2, you're going to have 6 nodes in total.

## Additional Notes
- While `e2-micro` is a viable option for `machine_type`, in practice it's not very useful as all the overhead that comes with GKE such as Stackdriver agent, `kube-dns`, `kube-proxy`, etc. consumes most of availble memory.  I recommend starting with at least an `e2-small` (2CPUs/2GB memory)
- Leaving [`release_channel`](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels) as `UNSPECIFIED` means that you will perform upgrades manually, where as if you subscribed to a channel, you will the get the regular updates that gets released to that channel
- At time of writing, enabling [Istio](https://istio.io) on the GKE cluster is a Beta feature and thus I have specified `provider = google-beta` in the `google_container_cluster` resource block
- Enabling Istio will add an NLB to the deployment which will increase your costs so unless you want to do something with the service mesh, I recommend leaving it disabled to save yourself some money :)
- Depending on your workload/application that you're running, you definitely could run most (or all) of it on a preemptible node pool in GCP, but if you're going to run production, please provision a **regional** cluster rather than cheap out for the free zonal one.


## Example
My `terraform.tfvars` and output of `terraform plan`:

```
project_id            = "my-project"
credentials_file_path = "/path/to/my/credentials.json"
region                = "northamerica-northeast1"
zone                  = "northamerica-northeast1-c"

channel      = "REGULAR"
auto_upgrade = "true"

gke_cluster_name = "playground"

machine_type = "e2-small"
disk_size_gb = "40"
max_nodes    = "1"
```

```
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_container_cluster.primary will be created
  + resource "google_container_cluster" "primary" {
      + additional_zones            = (known after apply)
      + cluster_ipv4_cidr           = (known after apply)
      + default_max_pods_per_node   = (known after apply)
      + enable_binary_authorization = false
      + enable_intranode_visibility = false
      + enable_kubernetes_alpha     = false
      + enable_legacy_abac          = false
      + enable_shielded_nodes       = true
      + enable_tpu                  = false
      + endpoint                    = (known after apply)
      + id                          = (known after apply)
      + initial_node_count          = 1
      + instance_group_urls         = (known after apply)
      + ip_allocation_policy        = (known after apply)
      + location                    = "northamerica-northeast1-c"
      + logging_service             = (known after apply)
      + master_version              = (known after apply)
      + monitoring_service          = (known after apply)
      + name                        = "playground"
      + network                     = "default"
      + node_locations              = (known after apply)
      + node_version                = (known after apply)
      + project                     = (known after apply)
      + region                      = (known after apply)
      + remove_default_node_pool    = true
      + services_ipv4_cidr          = (known after apply)
      + subnetwork                  = (known after apply)
      + tpu_ipv4_cidr_block         = (known after apply)
      + zone                        = (known after apply)

      + addons_config {
          + cloudrun_config {
              + disabled = (known after apply)
            }

          + horizontal_pod_autoscaling {
              + disabled = (known after apply)
            }

          + http_load_balancing {
              + disabled = false
            }

          + istio_config {
              + disabled = true
            }

          + kubernetes_dashboard {
              + disabled = (known after apply)
            }

          + network_policy_config {
              + disabled = (known after apply)
            }
        }

      + authenticator_groups_config {
          + security_group = (known after apply)
        }

      + cluster_autoscaling {
          + enabled = (known after apply)

          + resource_limits {
              + maximum       = (known after apply)
              + minimum       = (known after apply)
              + resource_type = (known after apply)
            }
        }

      + database_encryption {
          + key_name = (known after apply)
          + state    = (known after apply)
        }

      + maintenance_policy {
          + daily_maintenance_window {
              + duration   = (known after apply)
              + start_time = "03:00"
            }
        }

      + master_auth {
          + client_certificate     = (known after apply)
          + client_key             = (sensitive value)
          + cluster_ca_certificate = (known after apply)
          + password               = (sensitive value)
          + username               = (known after apply)

          + client_certificate_config {
              + issue_client_certificate = (known after apply)
            }
        }

      + network_policy {
          + enabled  = (known after apply)
          + provider = (known after apply)
        }

      + node_config {
          + disk_size_gb      = (known after apply)
          + disk_type         = (known after apply)
          + guest_accelerator = (known after apply)
          + image_type        = (known after apply)
          + labels            = (known after apply)
          + local_ssd_count   = (known after apply)
          + machine_type      = (known after apply)
          + metadata          = (known after apply)
          + min_cpu_platform  = (known after apply)
          + oauth_scopes      = (known after apply)
          + preemptible       = (known after apply)
          + service_account   = (known after apply)
          + tags              = (known after apply)

          + sandbox_config {
              + sandbox_type = (known after apply)
            }

          + shielded_instance_config {
              + enable_integrity_monitoring = (known after apply)
              + enable_secure_boot          = (known after apply)
            }

          + taint {
              + effect = (known after apply)
              + key    = (known after apply)
              + value  = (known after apply)
            }

          + workload_metadata_config {
              + node_metadata = (known after apply)
            }
        }

      + node_pool {
          + initial_node_count  = (known after apply)
          + instance_group_urls = (known after apply)
          + max_pods_per_node   = (known after apply)
          + name                = (known after apply)
          + name_prefix         = (known after apply)
          + node_count          = (known after apply)
          + node_locations      = (known after apply)
          + version             = (known after apply)

          + autoscaling {
              + max_node_count = (known after apply)
              + min_node_count = (known after apply)
            }

          + management {
              + auto_repair  = (known after apply)
              + auto_upgrade = (known after apply)
            }

          + node_config {
              + disk_size_gb      = (known after apply)
              + disk_type         = (known after apply)
              + guest_accelerator = (known after apply)
              + image_type        = (known after apply)
              + labels            = (known after apply)
              + local_ssd_count   = (known after apply)
              + machine_type      = (known after apply)
              + metadata          = (known after apply)
              + min_cpu_platform  = (known after apply)
              + oauth_scopes      = (known after apply)
              + preemptible       = (known after apply)
              + service_account   = (known after apply)
              + tags              = (known after apply)

              + sandbox_config {
                  + sandbox_type = (known after apply)
                }

              + shielded_instance_config {
                  + enable_integrity_monitoring = (known after apply)
                  + enable_secure_boot          = (known after apply)
                }

              + taint {
                  + effect = (known after apply)
                  + key    = (known after apply)
                  + value  = (known after apply)
                }

              + workload_metadata_config {
                  + node_metadata = (known after apply)
                }
            }
        }

      + release_channel {
          + channel = "REGULAR"
        }
    }

  # google_container_node_pool.primary_preemptible_nodes will be created
  + resource "google_container_node_pool" "primary_preemptible_nodes" {
      + cluster             = "playground"
      + id                  = (known after apply)
      + initial_node_count  = 1
      + instance_group_urls = (known after apply)
      + location            = "northamerica-northeast1-c"
      + max_pods_per_node   = (known after apply)
      + name                = "preempt-pool"
      + name_prefix         = (known after apply)
      + node_count          = (known after apply)
      + project             = (known after apply)
      + region              = (known after apply)
      + version             = (known after apply)
      + zone                = (known after apply)

      + autoscaling {
          + max_node_count = 1
          + min_node_count = 1
        }

      + management {
          + auto_repair  = true
          + auto_upgrade = true
        }

      + node_config {
          + disk_size_gb      = 40
          + disk_type         = (known after apply)
          + guest_accelerator = (known after apply)
          + image_type        = (known after apply)
          + labels            = (known after apply)
          + local_ssd_count   = (known after apply)
          + machine_type      = "e2-small"
          + metadata          = {
              + "disable-legacy-endpoints" = "true"
            }
          + oauth_scopes      = [
              + "https://www.googleapis.com/auth/logging.write",
              + "https://www.googleapis.com/auth/monitoring",
            ]
          + preemptible       = true
          + service_account   = (known after apply)

          + shielded_instance_config {
              + enable_integrity_monitoring = (known after apply)
              + enable_secure_boot          = (known after apply)
            }
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```
