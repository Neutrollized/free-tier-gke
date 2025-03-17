# HashiCorp Vault Integration
There are a few Vault integration options with Kubernetes:
- Vault Agent Injector
- Vault Secrets Operator (VSO)
- Vault CSI Provider

Vault Agent Injector uses a sidecar model which manages your secret and "injects" it to your main application by mounting it as a volume (hence it requires the PD CSI driver).  If you've used VMs with Vault Agents, this option will feel very familiar.

Vaut Secrets Operator is newer, and through various CRDs, will manage your auth and secrets for you and write it to a Kubernetes secret.  This is easier on resources as the sidecar model also comes with an overhead.  However, you need to have a stronger Kubernetes RBAC game here so not to make your k8s secret too accessible.

Vault CSI provider is the oldest one and I would opt for one of the other two options I mentioned above.  I wouldn't be surprised if this integration option were to be deprecated in the future.  You can read more about the differences between the Vault Agent Injector and Vault CSI Provider [here](https://developer.hashicorp.com/vault/docs/platform/k8s/injector-csi#vault-csi-provider).


## Install Vault in dev mode
For testing purposes, it's easy to run a single Vault instance in ["Dev" server mode](https://developer.hashicorp.com/vault/docs/concepts/dev-server):
```console
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault hashicorp/vault \
  --set="server.dev.enabled=true"
```

**NOTE 1**: for examples that I create here, I will likely be using this setup method

**NOTE 2**: because my cluster deployment is built upon ~~preemptible~~ spot nodes, there's chance the nodes can be terminated and replaced, which means the Vault dev server that stores configs and secrets *in-memory* will be reset, so please keep this in mind if you're doing any sort of testing and suddenly find things not working the way it did the days prior
