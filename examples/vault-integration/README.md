# Vault Integration
There are a few Vault integration options with Kubernetes:
- Agent Injector
- Vault Secrets Operator
- Vault CSI provider

If you want to learn about some of the differences, check [this](https://developer.hashicorp.com/vault/docs/platform/k8s/injector-csi) out.


## Install Vault in dev mode
For testing purposes, it's easy to run a single Vault instance in ["Dev" server mode](https://developer.hashicorp.com/vault/docs/concepts/dev-server):
```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault hashicorp/vault \
  --set="server.dev.enabled=true"
```

**NOTE 1**: for examples that I create here, I will likely be using this setup method

**NOTE 2**: because my cluster deployment is built upon preemptible nodes, it will be replaced ~24hrs, which means the Vault dev server that stores configs and secrets *in-memory* will be reset, so please keep this in mind if you're doing any sort of testing
