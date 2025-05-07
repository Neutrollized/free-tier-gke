# Argo CD 
- [Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

- v3.0.0:
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.0.0/manifests/install.yaml
```

- get admin password
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

- enable external load balancer
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

## Components
### Dex
- [Delegate authentication to EXternal identity providers](https://argocd-operator.readthedocs.io/en/latest/usage/dex/)


## Example repo & apps
The example (private) repository that I created, *Neutrollized/demo-app-argocd* contains some examples from [argoproj/argocd-example-apps](https://github.com/argoproj/argocd-example-apps)
