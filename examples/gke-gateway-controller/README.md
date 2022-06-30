# GKE Gateway Controller

Based on Google Cloud's [documented example](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways), but with some additional personal notes/fixes and uses [Cross-Namespace routing](https://gateway-api.sigs.k8s.io/v1alpha2/guides/multiple-ns/).

## Setup
#### 1. Install Gateway API CRDs:
```
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.3" | kubectl apply -f -
```

- verify install with `kubectl get gatewayclass` (may take a minute, so be patient):
```
NAME          CONTROLLER                  AGE
gke-l7-gxlb   networking.gke.io/gateway   51s
gke-l7-rilb   networking.gke.io/gateway   51s
```


## Deploying the Demo
#### 1. Create Namespaces with Labels
- create namespaces with lablel `shared-gateway-access: "true"`
```
kubectl apply -f namespaces.yaml
```

**NOTE:** only namespaces with the correct label will be able to attach their routes to the gateway


#### 2. Deploy an internal gateway: 
```
kubectl apply -f gateway.yaml
```

- verify with `kubectl describe gateway internal-http -n infra-ns` (ignore the warning for now, the backend it's complaining about is the default 404 page which Google provides, this will take a couple of minutes to provision):
```
...
...
Status:
  Addresses:
  Conditions:
    Last Transition Time:  1970-01-01T00:00:00Z
    Message:               Waiting for controller
    Reason:                NotReconciled
    Status:                False
    Type:                  Scheduled
Events:
  Type     Reason  Age               From                   Message
  ----     ------  ----              ----                   -------
  Normal   ADD     43s               sc-gateway-controller  infra-ns/internal-http
  Normal   UPDATE  43s               sc-gateway-controller  infra-ns/internal-http
  Warning  SYNC    5s                sc-gateway-controller  generic::invalid_argument: error ensuring load balancer: Insert: The resource 'projects/my-project/regions/northamerica-northeast1/backendServices/gkegw-3ac3-default-gw-serve404-80-mcfti8ucx6x5' is not ready
```


#### 3. Deploy Demo Store App
```
kubectl apply -f store.yaml
```


#### 4. Deploy HTTPRoute 
```
kubectl apply -f store-route.yaml
```

- verify with `kubectl describe httproute store -n store-ns`:
```
...
...
Status:
  Gateways:
    Conditions:
      Last Transition Time:  2021-12-01T19:38:00Z
      Message:
      Reason:                RouteAdmitted
      Status:                True
      Type:                  Admitted
      Last Transition Time:  2021-12-01T19:38:00Z
      Message:
      Reason:                ReconciliationSucceeded
      Status:                True
      Type:                  Reconciled
    Gateway Ref:
      Name:       internal-http
      Namespace:  default
Events:
  Type    Reason  Age                 From                   Message
  ----    ------  ----                ----                   -------
  Normal  ADD     3m40s               sc-gateway-controller  store-ns/store
  Normal  SYNC    2m43s               sc-gateway-controller  Bind of HTTPRoute "default/store" to Gateway "infra-ns/internal-http" was a success
  Normal  SYNC    2m43s               sc-gateway-controller  Reconciliation of HTTPRoute "store-ns/store" bound to Gateway "infra-ns/internal-http" was a success
```


#### 5. Deploy Demo Site App and Site HTTPRoute
- like the store, but for "site.example.com" instead:
```
kubectl apply -f store.yaml

kubectl apply -f store-route.yaml
```

**NOTE:** if it were GKE Ingress, you would not have this option as all routes are maintained in a single ingress definition


## Testing 
#### 1. Get the IP of the internal HTTP(s) load balancer:
```
kubectl get gateway internal-http -n infra-ns -o=jsonpath="{.status.addresses[0].value}"
```


#### 2. Send traffic!  
Since only internal traffic is allowed, I'm going to do the `curl` command via one the of the pods.

- `kubectl exec -it store-v2-6856f59f7f-7kj2w -n store-ns -- curl -H "host: store.example.com" 192.168.0.6`:
```
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
```
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
```
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

- kubectl exec -it store-v2-6856f59f7f-zrblv -n store-ns -- curl -H "host: site.example.com" 192.168.0.6`:
```
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
```
kubectl delete -f site-route.yaml
kubectl delete -f site.yaml
kubectl delete -f store-route.yaml
kubectl delete -f store.yaml
kubectl delete -f gateway.yaml
kubectl delete -f namespaces.yaml
```

You may also have to delete the backend services. I'm not sure why deleting the deployments doesn't clean them up, but you can verify with `gcloud compute backend-services list`.  You will have to delete them manually if they do still exist.

