# Free-tier GKE Cluster
[GKE Cluster](https://www.terraform.io/docs/providers/google/r/container_cluster.html)

[GKE Container Node Pool ](https://www.terraform.io/docs/providers/google/r/container_node_pool.html)

It's not 100% free, but with my 1 node setup, I'm paying ~$5USD/mth for a fully managed Kubernetes cluster.  This works by taking advantage of Google [always free](https://cloud.google.com/free/docs/gcp-free-tier) tier which waives the management fee of one **zonal** GKE cluster, so you only have to pay for your nodes.  Combine this with using [preemptible VMs](https://cloud.google.com/compute/docs/instances/preemptible) as your nodes and you'll have some spectacular savings.

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

### Additional Notes
- While `e2-micro` is a viable option for `machine_type`, in practice it's not very useful as all the overhead that comes with GKE such as Stackdriver agent, `kube-dns`, `kube-proxy`, etc. consumes most of availble memory.  I recommend starting with at least an `e2-small` (2CPUs/2GB memory)
- Leaving [`release_channel`](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels) as `UNSPECIFIED` means that you will perform upgrades manually, where as if you subscribed to a channel, you will the get the regular updates that gets released to that channel
- At time of writing, enabling [Istio](https://istio.io) on the GKE cluster is a Beta feature and thus I have specified `provider = google-beta` in the `google_container_cluster` resource block
- Enabling Istio will add an NLB to the deployment which will increase your costs so unless you want to do something with the service mesh, I recommend leaving it disabled to save yourself some money :)
- Depending on your workload/application that you're running, you definitely could run most (or all) of it on a preemptible node pool in GCP, but if you're going to run production, please provision a **regional** cluster rather than cheap out for the free zonal one
- If you deployed a private cluster, some of your k8s deployments may fail due to your pods [not having outbound access to the public Internet](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#docker_hub)...having said that, some of the more common images like the nginx one that I used in my examples folder may still work because you're [pulling from a Docker Hub cache](https://cloud.google.com/container-registry/docs/pulling-cached-images).  Ideally, you should be pulling images from your private GCR in this case

### Free Tier Background

According to [GCP's free tier](https://cloud.google.com/free), a free `f1-micro` instance is only available in one of the following regions: `us-west1`, `us-central1`, `us-east1`. Unfortunately, `f1-micro` instances are too small to run GKE.

### Example `terraform.tfvars`

```
project_id            = "my-project"
credentials_file_path = "/path/to/my/credentials.json"
region                = "northamerica-northeast1"
zone                  = "northamerica-northeast1-c"

channel      = "REGULAR"
auto_upgrade = "true"

gke_cluster_name        = "playground"
enable_private_endpoint = "false"
master_ipv4_cidr_block  = "172.16.0.0/28"
#istio_disabled   = "false"

machine_type = "e2-small"
disk_size_gb = "40"
max_nodes    = "1"
```

## Example Kubernetes Deployment
I've included an example deployment of nginx with *LoadBalancer* (GCP ALB) service.  Please note that the deployment does provision an GCP load balancer so this will incur extra charges if you leave it running for too long.

To deploy: `kubectl apply -f examples/nginx-deployment.yaml`

To delete: `kubectl delete -f examples/nginx-deployment.yaml`

The pods should deploy fairly quickly, but the service might take a bit before you get the load balancer's public IP (you can do a `watch kubectl get service` if you're the impatient type)

(There are also other examples in there if you want try them out as well)

## Using gcloud

The information above details out how to use terraform to deploy a low cost GKE cluster, but the [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstart) can be used to achieve a similar solution.

### Node configurations

The parameters for `location`, `node_locations` and `node_count` are a little different for the `gcloud` command.

`location` can be specified using the `--zone` flag for a zontal cluster.

`node_locations` has a corresponding `node-locations` flag.

`node_count` can be customized using `--num_nodes` for cluster level configurations, with `--max_nodes` and `-min_nodes` specifying the maximum or minimum number of nodes per zone.

### The information above
The full list of options for `gcloud container clusters create` can be found [here](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create) but the following is a minimal set of configurations to achieve a low cost cluster:

```
  gcloud container clusters create market-navigator \
    --zone us-west1-a \
    --node-locations us-west1-a \
    --machine-type=e2-small \
    --max-nodes=1 \
    --num-nodes=1
```
