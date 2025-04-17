# GKE Gateway Controller

Based on Google Cloud's [documented example](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways), but with some additional personal notes/fixes and uses [Cross-Namespace routing](https://gateway-api.sigs.k8s.io/v1alpha2/guides/multiple-ns/).

You can check out the [optional](./optional/README.md) steps for the full experience of connecting with service accounts that have namespace-restricted access.


## Setup
#### 1. Ensure GKE cluster meets requirements
- [GKE Gateway controller requirements](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways#requirements)
- currently requires a newer GKE version, best bet is to set `channel = "RAPID"`
- [Rapid channel release notes](https://cloud.google.com/kubernetes-engine/docs/release-notes-rapid)
- [Regular channel release notes](https://cloud.google.com/kubernetes-engine/docs/release-notes-regular)
- [Stable channel release notes](https://cloud.google.com/kubernetes-engine/docs/release-notes-stable)

#### 2. Enabling Gateway API:
- You can enable this by setting `var.gateway_api_channel` to `CHANNEL_STANDARD` (or `CHANNEL_EXPERIMENTAL`), but you can also update the cluster manually:
```sh
gcloud container clusters update playground \
    --gateway-api=standard \
    --zone=northamerica-northeast1-c
```

- verify install with `kubectl get gatewayclass -n kube-system` (may take a minute, so be patient):
```console
NAME                               CONTROLLER                  ACCEPTED   AGE
gke-l7-global-external-managed     networking.gke.io/gateway   True       6m44s
gke-l7-gxlb                        networking.gke.io/gateway   True       6m44s
gke-l7-regional-external-managed   networking.gke.io/gateway   True       6m44s
gke-l7-rilb                        networking.gke.io/gateway   True       6m44s
```


## Deploying the Demo
#### 1. Create Namespaces with Labels
- create namespaces with label `shared-gateway-access: "true"`
```sh
kubectl apply -f namespaces.yaml
```

**NOTE:** only namespaces with the correct label will be able to attach their routes to the gateway


#### 2. Deploy an internal gateway: 
```sh
kubectl apply -f gateway.yaml
```

- verify with `kubectl describe gateway internal-http -n infra-ns`:
```console
...
...
Events:
  Type    Reason  Age                From                   Message
  ----    ------  ----               ----                   -------
  Normal  ADD     83s                sc-gateway-controller  infra-ns/internal-http
  Normal  UPDATE  28s (x3 over 83s)  sc-gateway-controller  infra-ns/internal-http
  Normal  SYNC    28s                sc-gateway-controller  SYNC on infra-ns/internal-http was a success
```


#### 3. Deploy Demo Store App
```sh
kubectl apply -f store.yaml
```


#### 4. Deploy HTTPRoute 
```sh
kubectl apply -f store-route.yaml
```

- verify with `kubectl describe httproute store -n store-ns`:
```console
...
...
    Controller Name:         networking.gke.io/gateway
    Parent Ref:
      Group:      gateway.networking.k8s.io
      Kind:       Gateway
      Name:       internal-http
      Namespace:  infra-ns
Events:
  Type    Reason  Age   From                   Message
  ----    ------  ----  ----                   -------
  Normal  ADD     89s   sc-gateway-controller  store-ns/store
  Normal  SYNC    29s   sc-gateway-controller  All the object references were able to be resolved for HTTPRoute "store-ns/store" bound to ParentRef {Group:       "gateway.networking.k8s.io",
 Kind:        "Gateway",
 Namespace:   "infra-ns",
 Name:        "internal-http",
 SectionName: nil,
 Port:        nil}
  Normal  SYNC  29s  sc-gateway-controller  Bind of HTTPRoute "store-ns/store" to ParentRef {Group:       "gateway.networking.k8s.io",
 Kind:        "Gateway",
 Namespace:   "infra-ns",
 Name:        "internal-http",
 SectionName: nil,
 Port:        nil} was a success
  Normal  SYNC  29s  sc-gateway-controller  Reconciliation of HTTPRoute "store-ns/store" bound to ParentRef {Group:       "gateway.networking.k8s.io",
 Kind:        "Gateway",
 Namespace:   "infra-ns",
 Name:        "internal-http",
 SectionName: nil,
 Port:        nil} was a success
```


#### 5. Deploy Demo Site App and Site HTTPRoute
- like the store, but for "site.example.com" instead:
```sh
kubectl apply -f site.yaml

kubectl apply -f site-route.yaml
```

**NOTE:** if it were GKE Ingress, you would not have this option as all routes are maintained in a single ingress definition


## Testing 
#### 1. Get the IP of the internal HTTP(s) load balancer:
```sh
kubectl get gateway internal-http -n infra-ns -o=jsonpath="{.status.addresses[0].value}"
```


#### 2. Send traffic!  
Since only internal traffic is allowed, I'm going to do the `curl` command via one the of the pods.

- `kubectl exec -it store-v2-6856f59f7f-7kj2w -n store-ns -- curl -H "host: store.example.com" 192.168.0.6`:
```JSON
{
  "cluster_name": "playground",
  "host_header": "store.example.com",
  "metadata": "store-v1",
  "node_name": "gke-playground-preempt-pool-3e55f4cf-wv3m.northamerica-northeast1-c.c.my-project.internal",
  "pod_name": "store-v1-65b47557df-m45h6",
  "pod_name_emoji": "🙅",
  "project_id": "my-project",
  "timestamp": "2021-12-01T20:06:00",
  "zone": "northamerica-northeast1-c"
}
```
**NOTE:** I am using the [traffic splitting](https://gateway-api.sigs.k8s.io/v1alpha2/guides/traffic-splitting/) of the Gateway API (which is normally a feature you would only find with serivce meshes), so you may hit *store-v2*

- `kubectl exec -it store-v2-6856f59f7f-7kj2w -n store-ns -- curl -H "host: store.example.com" -H "env: canary" 192.168.0.6`:
```JSON
{
  "cluster_name": "playground",
  "host_header": "store.example.com",
  "metadata": "store-v2",
  "node_name": "gke-playground-preempt-pool-3e55f4cf-wv3m.northamerica-northeast1-c.c.my-project.internal",
  "pod_name": "store-v2-6856f59f7f-7ssxq",
  "pod_name_emoji": "💇",
  "project_id": "my-project",
  "timestamp": "2021-12-01T20:08:20",
  "zone": "northamerica-northeast1-c"
}
```

- `kubectl exec -it store-v2-6856f59f7f-7kj2w -n store-ns -- curl -H "host: store.example.com" 192.168.0.6/de`: 
```JSON
{
  "cluster_name": "playground",
  "host_header": "store.example.com",
  "metadata": "Gutentag!",
  "node_name": "gke-playground-preempt-pool-3e55f4cf-tn65.northamerica-northeast1-c.c.my-project.internal",
  "pod_name": "store-german-66dcb75977-8gqv7",
  "pod_name_emoji": "🧗",
  "project_id": "my-project",
  "timestamp": "2021-12-01T20:03:57",
  "zone": "northamerica-northeast1-c"
}
```

- `kubectl exec -it store-v2-6856f59f7f-zrblv -n store-ns -- curl -H "host: site.example.com" 192.168.0.6`:
```JSON
{
  "cluster_name": "playground",
  "host_header": "site.example.com",
  "metadata": "site-v1",
  "node_name": "gke-playground-preempt-pool-935e4e41-86nn.northamerica-northeast1-c.c.my-project.internal",
  "pod_name": "site-v1-86dc4b4fbc-gt4kw",
  "pod_name_emoji": "👨🏾‍🔬",
  "project_id": "my-project",
  "timestamp": "2022-06-02T21:43:03",
  "zone": "northamerica-northeast1-c"
}
```


## Cleanup
```sh
kubectl delete -f site-route.yaml
kubectl delete -f site.yaml
kubectl delete -f store-route.yaml
kubectl delete -f store.yaml
kubectl delete -f gateway.yaml
kubectl delete -f namespaces.yaml
```

You may also have to delete the backend services. I'm not sure why deleting the deployments doesn't clean them up, but you can verify with `gcloud compute backend-services list`.  You will have to delete them manually if they do still exist.

