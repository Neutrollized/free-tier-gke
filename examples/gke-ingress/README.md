# GKE Ingress

The services in this example all utilize the [fake-service](https://github.com/nicholasjackson/fake-service) container created by [Nic Jackson](https://github.com/nicholasjackson)

Apply the gxlb-ingress.yaml to deploy an [external HTTP(S) load balancer](https://cloud.google.com/load-balancing/docs/https) and the rilb-ingress.yaml to deploy an [internal HTTP(S) load balancer](https://cloud.google.com/load-balancing/docs/l7-internal)

the `/ui` endpoint in a web browser will show you a graphical representation of how the services are connected.

> [!IMPORTANT]
> You may see a deprecation warning regarding the `kubernetes.io/ingress.class` annotation, but please not not attempt to fix as per [documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#deprecated_annotation)

## BackendConfig
- used to define health check rules
- used to attach Cloud Armor security policies

## Google-managed SSL certs
[Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)
