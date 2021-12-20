# GKE Ingress

The services in this example all utilize the [fake-service](https://github.com/nicholasjackson/fake-service) container created by [Nic Jackson](https://github.com/nicholasjackson)

Apply the gxlb-ingress.yaml to deploy an [external HTTP(S) load balancer](https://cloud.google.com/load-balancing/docs/https) and the rilb-ingress.yaml to deploy an [internal HTTP(S) load balancer](https://cloud.google.com/load-balancing/docs/l7-internal)

the `/ui` endpoint in a web browser will show you a graphical representation of how the services are connected.
