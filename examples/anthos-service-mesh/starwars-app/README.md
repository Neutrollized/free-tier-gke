# README
App based on the [Starwars demo](https://github.com/cilium/star-wars-demo) from Cilium

## Deploy the Starwars App
```sh
kubectl apply -f namespace.yaml

kubectl apply -f http-sw-app.yaml
kubectl apply -f deathstar-gateway.yaml
```

### AuthorizationPolicy (optional)
```sh
kubectl apply -f deathstar-authzpolicy.yaml
```

## Testing
- allowed requests
```sh
curl -XGET -H "Host: deathstar.galaxy.com" http://$(kubectl get svc -n asm-gateway --output jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')/v1/

curl -XPOST -H "Host: deathstar.galaxy.com" http://$(kubectl get svc -n asm-gateway --output jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')/v1/request-landing

curl -XPUT -H "Host: deathstar.galaxy.com" http://$(kubectl get svc -n asm-gateway --output jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')/v1/exhaust-port
```

- sample denied requests (returns **RBAC: access denied**)
```sh
curl -XPUT -H "Host: deathstar.galaxy.com" http://$(kubectl get svc -n asm-gateway --output jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')/v1/request-landing

curl -XGET -H "Host: deathstar.galaxy.com" http://$(kubectl get svc -n asm-gateway --output jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')/v1/exhaust-port
```

## Cleanup
```sh
kubectl delete -f deathstar-authzpolicy.yaml
kubectl delete -f deathstar-gateway.yaml
kubectl delete -f http-sw-app.yaml
kubectl delete -f namespace.yaml
```
