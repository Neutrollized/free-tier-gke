# Anthos Service Mesh (ASM)
ASM can be installed on GKE as a standalone service and [does not require an Anthos subscription](https://cloud.google.com/service-mesh/docs/unified-install/anthos-service-mesh-prerequisites#licensing).

## Requirements
- The following APIs enabled:
```console
gcloud services enable --async \
  gkehub.googleapis.com \
  meshconfig.googleapis.com \
  meshca.googleapis.com
```
- Workload Identity enabled (which it should be already if you are using my Terraform blueprint)

NOTE 1: despite the documentation saying the [cluster requirements](https://cloud.google.com/service-mesh/docs/unified-install/anthos-service-mesh-prerequisites#cluster_requirements) as needing at least 2 nodes and 8 vCPUs, my example here works even on a single, n2-standard-2 node (2 vCPU, 8GB mem)

NOTE 2: the **mesh_id** label is only required for multi-cluster deployments -- not necessary in a standalone


## Enable ASM
```console
gcloud container fleet mesh enable --project ${PROJECT_ID}
```

```console
gcloud container fleet membership register ${GKE_CLUSTER_NAME}-membership \
  --gke-cluster=${GKE_LOCATION}/${GKE_CLUSTER_NAME} \
  --enable-workload-identity \
  --project ${PROJECT_ID}
```

```console
gcloud container fleet mesh update \
  --management automatic \
  --memberships ${GKE_CLUSTER_NAME}-membership \
  --project ${PROJECT_ID}
```

### Verify
- Takes ~5-10 min to provision, note the "**Revision(s) ready for use**" as you will require that a little later on.
```console
gcloud container fleet mesh describe --project ${PROJECT_ID}
```

- Example output:
```
...
...
    servicemesh:
      controlPlaneManagement:
        details:
        - code: REVISION_READY
          details: 'Ready: asm-managed-rapid'
        state: ACTIVE
      dataPlaneManagement:
        details:
        - code: OK
          details: Service is running.
        state: ACTIVE
    state:
      code: OK
      description: |-
        Revision(s) ready for use: asm-managed-rapid.
...
...
```


## Deploying the Demo
The gateway manifests used here is from [Anthos Service Mesh Packages](https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages/tree/main/samples), but with some minor updates/modifications.

For the app, I will be using the [Bookinfo sample](https://github.com/istio/istio/tree/master/samples/bookinfo) here (seems only fitting).

### Deploy Ingress Gateway
You will need a namespace for your ASM gateway.  Here I just called it **asm-gateway** (original, I know).  We will be using the [revision](https://cloud.google.com/service-mesh/docs/revisions-overview#what_is_a_revision) as the auto-injection label.

The revision can be found in the output of the verification step above, or you can run: `kubectl -n istio-system get controlplanerevision`

```console
kubectl create ns asm-gateway
kubectl label ns asm-gateway istio.io/rev=asm-managed-rapid

kubectl apply -f gateways/istio-ingressgateway -n asm-gateway
```

```console
kubectl get service -n asm-gateway
```

### Deploy Sample App
We will use the same auto-injection label for the namespace in which we will be deploying our sample application.

```console
kubectl create ns bookinfo
kubectl label ns bookinfo istio.io/rev=asm-managed-rapid

kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
```

### Expose Application 
```console
kubectl apply -f istio-manifests/productpage-gateway.yaml
```



## Additional Notes
I've added some fault injection and circuit breaking into to the **VirtualService** and **DestinationRule** respectively, which you can comment out if you wish.  You can use a tool like [`fortio`](https://github.com/fortio/fortio) to perform load testing (i.e. `fortio load -c 3 -qps 0 -n 50 -loglevel Warning http://$(kubectl get svc -n asm-gateway --output jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')`).

Some useful security configurations to know are [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/) and [AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/)

Despite its name, **ServiceEntry** is used *allow* your pods egress to the Internet (i.e. external services/APIs). 

**AuthorizationPolicy**, on the other hand, is more for ingress controls.  I included some [sample policies](./istio-manifests/authorization-policies) here that you can try out if you wish.


## Cleanup
```console
kubectl delete -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
kubectl delete -f gateways/istio-ingressgateway -n asm-gateway

gcloud container fleet memberships delete ${GKE_CLUSTER_NAME}-membership
```
