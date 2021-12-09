# Traffic Director with Automatic Envoy Injection

The steps used in this example is taken from [here](https://cloud.google.com/traffic-director/docs/set-up-gke-pods-auto) with my own added notes.


## Prerequisite
- enable **Traffic Director API**


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

**NOTE:** if you're using MacOS, it's likely your openssl version won't have the `-addext` option, in which case you will have to `brew install openssl`, which should install `openssl@3`, and you will have to reference that version instead.  For me, that path was `/usr/local/opt/openssl@3/bin/openssl`

I've also generated a set of keys that you can use if you wish if you don't already have your own or if you're just feeling lazy.


#### Enabling sidecar injection
```
kubectl label namespace default istio-injection=enabled
```

You can see which namespaces have injection enabled with:
```
kubectl get namespace -L istio-injection
```

**NOTE:** if you're enabling this on an existing cluster with workload, enabling istio-injection will not add sidecars to existing workload -- you will have restart them


#### Creating the backend service
If you created a regional cluster, adding backend services is the same, except you have to add every zone.


#### Creating the routing rule map
If you read the documention, you will see its mention of a virtual IP (VIP) address whose traffic gets intercepted by the Envoy sidecar.  The VIP is actually the address in the forwarding rule.  In the documentation they just use `0.0.0.0` without a detailed explanation.  I'm going to specify one (`192.168.9.9`):
```
VIP=192.168.9.9

gcloud compute forwarding-rules create td-gke-forwarding-rule \
  --global \
  --load-balancing-scheme=INTERNAL_SELF_MANAGED \
  --address=${VIP} \
  --target-http-proxy=td-gke-proxy \
  --ports 80 --network default
```

In the verifying the configuration step, it does:
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
gcloud compute firewall-rules delete fw-allow-health-checks
gcloud compute health-checks delete td-gke-health-check
```

```
kubectl delete -f trafficdirector_service_sample.yaml
kubectl delete -f client_sample.yaml
```

You may also have to delete the NEGs that are listed relating to your service (but wait a bit first, it may tak some time):
```
gcloud compute network-endpoint-groups list
```
