# NGINX Ingress

Most of the example is taken from [here](https://cloud.google.com/community/tutorials/nginx-ingress-gke) with my own notes added.

The services in this example all utilize the [fake-service](https://github.com/nicholasjackson/fake-service) container created by [Nic Jackson](https://github.com/nicholasjackson)


## Install Ingress Controller with Helm
- add repo:
```console
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

- deploy NGINX ingress controller (this creates a TCP/UDP load balancer in GCP)
- wait until you get an external IP
```console
helm install nginx-ingress ingress-nginx/ingress-nginx
```

- deploy Ingress resource
```console
kubectl apply -f ./nginx-ingress-rewrite.yaml
```

## NOTES
- access the endpoint at `http://${LOAD_BALANCER_IP}/${ENDPOINT}`
- you need to specify `kubernetes.io/ingress.class: "nginx"` otherwise it will default to `"gce"` and your rewrite rules won't work as expected
- example:
```
metadata:
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/hello(/|$)(.*)"
        backend:
          service:
            name: web
            port:
              number: 80
```

- the example above will rewrite `http://${LOAD_BALANCER_IP}/hello/test` to `http://${LOAD_BALANCER_IP}/test`
