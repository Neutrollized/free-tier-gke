# Free-tier GKE Cluster
[GKE Cluster](https://www.terraform.io/docs/providers/google/r/container_cluster.html)

[GKE Container Node Pool ](https://www.terraform.io/docs/providers/google/r/container_node_pool.html)

It's not 100% free, but with my 1 node setup, I'm paying ~$5USD/mth for a fully managed Kubernetes cluster.  This works by taking advantage of Google [always free](https://cloud.google.com/free/docs/gcp-free-tier) tier which waives the management fee of one **zonal** GKE cluster, so you only have to pay for your nodes.  Combine this with using [preemptible VMs](https://cloud.google.com/compute/docs/instances/preemptible) as your nodes and you'll have some spectacular savings.

This is great if you're looking for a small k8s cluster that more closely resembles what you might see in the real world (not that [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) or [MicroK8s](https://microk8s.io/) isn't good as a learning tool -- it's just not the same).  Here, you can also scale in/out your cluster easily if you want test some features or add-ons (like service meshes!).

## GKE vs EKS vs AKS
I'm going to use a single node (2CPUs/4GB memory) Kubernetes cluster as the basis for comparison between the 3 major cloud providers.  The math is shown below, but it doesn't take an extreme couponer to figure out which is the best deal.

#### GKE
- 1 free zonal GKE cluster
- e2-medium @ $27USD/mth (or $8USD/mth for [preemptible](https://cloud.google.com/compute/docs/instances/preemptible))

#### EKS
- $0.10/hr per EKS cluster @ 730hrs/mth (or $73USD/mth)
- t3.medium @ $29USD/mth ([Spot](https://aws.amazon.com/ec2/spot/?cards.sort-by=item.additionalFields.startDateTime&cards.sort-order=asc) instances available at up to 90% savings)

#### AKS
- [free cluster management](https://azure.microsoft.com/en-ca/pricing/details/kubernetes-service/)
- B2S @ $34USD/mth ([Spot](https://azure.microsoft.com/en-us/pricing/spot/) instances available at up to 90% savings)

Azure's AKS combined with Spot instances are actually incredibly competitive in pricing vs preemptibles, but in my mind, preemptibles have the edge due to ease of use -- no price bidding and a generably more reliable/predictable uptime (in my use don't think I've had any node get terminated before 22hrs).


## IMPORTANT
The key to getting the savings here is to limit the amount of nodes in your cluster (until you need it).  The 3 key settings to ensure this is `location`, `node_locations` and `node_count` (or `initial_node_count`).  

`location` specifies where to place the cluster (masters).  By specifying a zone, you have a free, zonal cluster.  If you replaced it with a region instead, it becomes a regional cluster -- ideal for a production cluster, but not part of the free tier offering.

Leaving `node_locations` blank will default your node to be in the same zone as your GKE cluster's zone.  Any zone you specify will be **in addition** to the the cluster's zone (i.e. `node_locations = ["northamerica-northeast1-a",]`), meaning your nodes will span more than one zone.  This is referred to as a multi-zone cluster.

`node_count` specifies how many nodes **per zone** rather than the total node count in your cluster.  Therefore, if you set 3 zones in `node_locations` with a `node_count` of 2, you're going to have 6 nodes in total.

### Enable Required APIs
You can do this via console or...
```
gcloud services enable --async \
  container.googleapis.com
```

### Additional Notes
- While `e2-micro` is a viable option for `machine_type`, in practice it's not very useful as all the overhead that comes with GKE such as Stackdriver agent, `kube-dns`, `kube-proxy`, etc. consumes most of availble memory.  I recommend starting with at least an `e2-small` (2CPUs/2GB memory)
- Leaving [`release_channel`](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels) as `UNSPECIFIED` means that you will perform upgrades manually, where as if you subscribed to a channel, you will the get the regular updates that gets released to that channel
- At time of writing, enabling [Istio](https://istio.io) on the GKE cluster is a Beta feature and thus I have specified `provider = google-beta` in the `google_container_cluster` resource block
- Enabling Istio will add an NLB to the deployment which will increase your costs so unless you want to do something with the service mesh, I recommend leaving it disabled to save yourself some money :)
- Depending on your workload/application that you're running, you definitely could run most (or all) of it on a preemptible node pool in GCP, but if you're going to run production, please provision a **regional** cluster rather than cheap out for the free zonal one
- If you deployed a private cluster, some of your k8s deployments may fail due to your pods [not having outbound access to the public Internet](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#docker_hub)...having said that, some of the more common images like the nginx one that I used in my examples folder may still work because you're [pulling from a Docker Hub cache](https://cloud.google.com/container-registry/docs/pulling-cached-images).  Ideally, you should be pulling images from your private GCR in this case
- If `confidential_nodes_enabled` is set to true, the `machine_type` needs to be from the [N2D family](https://cloud.google.com/kubernetes-engine/docs/how-to/confidential-gke-nodes) where the smallest node size starts at `n2d-standard-2` (2CPUs/8GB memory) and it must also NOT be a preemptible node (which effectively nullifies one of the cost-saving components of this free-tier GKE)


## eBPF, Cilium and GKE Dataplane V2
Over the last serveral weeks, I've been learning a lot about [eBPF](https://ebpf.io/) and experimenting with [Cilium](https://cilium.io/) in particular.  It was the main reason behind the changes in [v0.3.2](https://github.com/Neutrollized/free-tier-gke/blob/master/CHANGELOG.md#032---2021-08-26).  New in [v0.4.0](https://github.com/Neutrollized/free-tier-gke/blob/master/CHANGELOG.md#040---2021-09-09), you will have the option of enabling [GKE Dataplane V2](https://cloud.google.com/blog/products/containers-kubernetes/bringing-ebpf-and-cilium-to-google-kubernetes-engine) which leverages the power of eBPF and Cilium to provide enhanced security and observability in your GKE cluster.  

When Dataplane V2 is enabled, one of the things you may notice is the absence of **kube-proxy** in the cluster.  That's becuase it has been replaced by Cilium CNI!  It replaces iptables as compoent that controls connections between pods (and between nodes). Iptables is an old-school (albeit, extensive and powerful) program that allows the configuration of (mainly static) IP packet filter rules in a Linux kernel firewall and was never meant for something as dynamic as a Kubernetes environment.  The sheer number of iptables rules in very large clusters makes scaling difficult and hence a kube-proxy replacement such as Cilium would be very welcomed in such a scenario.

If you would like to learn more about Cilium and how to get started, I wrote a short Medium article about it [here](https://medium.com/@glen.yu/getting-started-with-ebpf-and-cilium-on-gke-6553c5d7e02a).

## Example Kubernetes Deployment
I've included an example deployment of nginx with *LoadBalancer* (GCP ALB) service.  Please note that the deployment does provision an GCP load balancer so this will incur extra charges if you leave it running for too long.

To deploy: `kubectl apply -f examples/nginx-deployment.yaml`

To delete: `kubectl delete -f examples/nginx-deployment.yaml`

The pods should deploy fairly quickly, but the service might take a bit before you get the load balancer's public IP (you can do a `watch kubectl get service` if you're the impatient type)

(There are also other examples in there if you want try them out as well)
