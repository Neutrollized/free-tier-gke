# Prometheus

I recommend when you're first starting out and trying Prometheus (not to be confused with [Google Cloud Managed Prometheus](https://cloud.google.com/stackdriver/docs/managed-prometheus)), is to use one of the [community helm charts](https://github.com/prometheus-community/helm-charts)

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack \
  --create-namespace \
  -n kube-prometheus-stack \
  -f myvalues.yaml \
  prometheus-community/kube-prometheus-stack
```

**NOTE**: This is the [default values.yaml](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml), but since I don't need everything the stack has to offer at the moment, I'm just going to use my own.

- these are a couple of aliases that I use to get quick access to the Prometheus and Grafana web UIs:
```sh
alias kprometheusui='kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-prometheus 9090:9090'

alias kgrafanaui='kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 3000:80'
```

### Cleanup
```
helm delete kube-prometheus-stack -n kube-prometheus-stack
```
