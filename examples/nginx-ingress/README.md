# NGINX Ingress

Most of the example is taken from [here](https://cloud.google.com/community/tutorials/nginx-ingress-gke) with my own notes added.

The services in this example all utilize the [fake-service](https://github.com/nicholasjackson/fake-service) container created by [Nic Jackson](https://github.com/nicholasjackson)


## Install Ingress Controller with Helm
- add repo:
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

- deploy NGINX ingress controller (this creates a TCP/UDP load balancer in GCP)
- wait until you get an external IP
```
helm install nginx-ingress ingress-nginx/ingress-nginx
```

- deploy services
```
kubectl apply -f ./currency.yaml
kubectl apply -f ./payments.yaml
kubectl apply -f ./web.yaml
```

- deploy Ingress resource (with rewrite)
```
kubectl apply -f ./nginx-ingress-rewrite.yaml
```

## NOTES
- access the endpoint at `http://${LOAD_BALANCER_IP}/${ENDPOINT}`
- you need to specify `spec.ingressClassName: nginx` otherwise it will default to `"gce"` and your rewrite rules won't work as expected
- example:
```yaml
...
...
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - pathType: ImplementationSpecific
        path: /hello(/|$)(.*)
        backend:
          service:
            name: web
            port:
              number: 80
```

The example above will rewrite `http://${LOAD_BALANCER_IP}/hello/web` to `http://${LOAD_BALANCER_IP}/web`.  If you're using my sample code for rewrite, *nginx-ingress-rewrite.yaml*, then you will need to specify a host header as well such as:
```sh
curl -H "host: mysite.example.com" http://${LOAD_BALANCER_IP}/hello/payments

curl -H "host: mysite.example.com" http://${LOAD_BALANCER_IP}/world/currency
```


## Cleanup
```
kubectl delete -f ./currency.yaml
kubectl delete -f ./payments.yaml
kubectl delete -f ./web.yaml

kubectl delete -f ./nginx-ingress-rewrite.yaml

helm uninstall nginx-ingress
```
