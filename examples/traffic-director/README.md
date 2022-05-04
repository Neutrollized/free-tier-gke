# Traffic Director with Automatic Envoy Injection

The steps used in this example is taken from [here](https://cloud.google.com/traffic-director/docs/set-up-gke-pods-auto) with my own added notes.


## Prerequisite
- enable **Traffic Director API**
- GKE cluster has scope: **"https://www.googleapis.com/auth/cloud-platform"**


#### Configuring TLS for sidecar injector
```
CN=istio-sidecar-injector.istio-control.svc

openssl req \
  -x509 \
  -newkey rsa:4096 \
  -keyout key.pem \
  -out cert.pem \
  -days 365 \
  -nodes \
  -subj "/CN=${CN}" \
  -addext "subjectAltName=DNS:${CN}"
```

**MacOS NOTE:** it's likely the default MacOS openssl version won't have the `-addext` option, in which case you will have to `brew install openssl`, which should install `openssl@3`, and you will have to reference that version instead.  For me, that path was `/usr/local/opt/openssl@3/bin/openssl`

I've also generated a set of keys that you can use if you wish if you don't already have your own or if you're just feeling lazy.


#### Enabling sidecar injection
```
kubectl apply -f specs/00-namespaces.yaml
```

```
kubectl label namespace default istio-injection=enabled
```

You can see which namespaces have injection enabled with:
```
kubectl get namespace -L istio-injection
```

```
kubectl create secret generic istio-sidecar-injector -n istio-control \
  --from-file=tls-certs/key.pem \
  --from-file=tls-certs/cert.pem \
  --from-file=tls-certs/ca-cert.pem
```

```
CA_BUNDLE=$(cat tls-certs/cert.pem | base64 | tr -d '\n')
sed -i "s/caBundle:.*/caBundle:\ ${CA_BUNDLE}/g" specs/02-injector.yaml
```

**MacOS NOTE:** the MacOS `sed` command equivalent is: `sed -i '' "s/caBundle:.*/caBundle:\ ${CA_BUNDLE}/g" specs/02-injector.yaml`

**NOTE:** if you're enabling this on an existing cluster with workload, enabling istio-injection will not add sidecars to existing workload -- you will have restart them


#### Creating the backend service
If you created a regional cluster, adding backend services is the same, except you have to add every zone.


```
gcloud compute health-checks create http td-gke-health-check \
  --use-serving-port
```

```
gcloud compute backend-services create td-gke-service \
 --global \
 --health-checks td-gke-health-check \
 --load-balancing-scheme INTERNAL_SELF_MANAGED
```

Adding backend services (if unsure of NEG values, do: `gcloud compute network-endpoint-groups list`)
```
gcloud compute backend-services add-backend td-gke-service \
 --global \
 --network-endpoint-group service-test-neg \
 --network-endpoint-group-zone northamerica-northeast1-c \
 --balancing-mode RATE \
 --max-rate-per-endpoint 5
```


#### Creating the routing rule map
```
gcloud compute url-maps create td-gke-url-map \
   --default-service td-gke-service
```

```
gcloud compute url-maps add-path-matcher td-gke-url-map \
   --default-service td-gke-service \
   --path-matcher-name td-gke-path-matcher

gcloud compute url-maps add-host-rule td-gke-url-map \
   --hosts service-test \
   --path-matcher-name td-gke-path-matcher
```

```
gcloud compute target-http-proxies create td-gke-proxy \
   --url-map td-gke-url-map
```

If you read the documention, you will see its mention of a virtual IP (VIP) address whose traffic gets intercepted by the Envoy sidecar.  The VIP is actually the address in the forwarding rule.  In the documentation they just use `0.0.0.0` without a detailed explanation.  I'm going to specify one (`192.168.9.9`):
```
VIP=192.168.9.9

gcloud compute forwarding-rules create td-gke-forwarding-rule \
  --global \
  --load-balancing-scheme=INTERNAL_SELF_MANAGED \
  --address=${VIP} \
  --target-http-proxy=td-gke-proxy \
  --ports 80 --network playground-k8s-vpc
```

#### Verifying the configuration
Please be patient -- sometimes it can take several minutes before the test command below will return a valid response.  The error you may see is "wget: can't connect to remote host (192.168.9.9): Connection refused":
```
BUSYBOX_POD=$(kubectl get po -l run=client -o=jsonpath='{.items[0].metadata.name}')

TEST_CMD="wget -q --header 'Host: service-test' -O - 192.168.9.9; echo"

kubectl exec -it $BUSYBOX_POD -c busybox -- /bin/sh -c "$TEST_CMD"
```

**NOTE**: you might be curious as to where the `10.0.0.1` IP came from in the documented example.  It explains that because the VIP of `0.0.0.0` is used in their forwarding rule, that it essentially listens on all addresses, hence you can pass in any and it will be accepted.  In my example, I gave it a explicit address for the VIP, so anything other than the correct VIP will produce a `wget: error getting response: Connection reset by peer` error.


## Cleanup
Assuming you followed the naming in the example, these are the commands to delete the resources you created:
```
gcloud compute forwarding-rules delete td-gke-forwarding-rule --global
gcloud compute target-http-proxies delete td-gke-proxy
gcloud compute url-maps delete td-gke-url-map
gcloud compute backend-services delete td-gke-service --global
gcloud compute health-checks delete td-gke-health-check
```

```
kubectl delete -f trafficdirector_service_sample.yaml
kubectl delete -f client_sample.yaml
```
