# Cluster Mesh

## GKE-to-AKS
I have a [Free Tier AKS](https://github.com/Neutrollized/free-tier-aks) repo for creating a fairly low-cost Azure Kubernetes Service cluster and if you wish, you can deploy that along with this free tier GKE. **However**, you will have to create a VPN tunnel between the two cloud providers, and that can be costly.

## Optionally: GKE-to-GKE (recommended!)
This is a cheaper option because unlike other cloud providers where their VPCs are regionally scoped, Google's VPCs are global, so a GKE cluster in Asia can communicate with a GKE cluster in South America internally by default (provided they're in the same VPC).

Currently, this repo only creates a single GKE cluster in a single subnet in the VPC, but you can create the missing resources on top of this if you'd like.

I wrote [Cilium's documentation](https://docs.cilium.io/en/stable/network/clustermesh/gke-clustermesh-prep/) for getting a "quick and dirty" environment up and running to set up a Cilium clustermesh. 


### Enable ClusterMesh
```
cilium clustermesh enable --context ${CONTEXT1} --enable-kvstoremesh
cilium clustermesh enable --context ${CONTEXT2} --enable-kvstoremesh
```

- (recommended) match Cillium CA certs
```
kubectl --context=${CONTEXT2} delete secret -n kube-system cilium-ca

kubectl --context=${CONTEXT1} get secret -n kube-system cilium-ca -o yaml | \
  kubectl --context=${CONTEXT2} create -f -
```

**NOTE** - if you don't have matching certs, you'll get something like the following when you connect your clusters:
```
...
⚠️ Cilium CA certificates do not match between clusters. Multicluster features will be limited!
ℹ️ Configuring Cilium in cluster 'gke-1' to connect to cluster 'gke-2'
ℹ️ Configuring Cilium in cluster 'gke-2' to connect to cluster 'gke-1'
...
```

### Connect clusters
```
cilium clustermesh connect --context ${CONTEXT1} --destination-context ${CONTEXT2}
```

## Demo!
I'm using NGINX ingress controller here, but basically you want to deploy the services in BOTH clusters, but the ingress controller in **ONLY ONE**.

- installing NGINX ingress controller via Helm:
```console
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx
```

Afterwards, you can it up *http://[LOADBALANCER_IP]/ui* and refresh to watch the services being balanced across both clusters.  You can even delete the web deployment (but NOT the service, as it's the service that's global) on the cluster where the ingress controller is running and everything will still work as it will route to the pods in the other cluster instead.  
