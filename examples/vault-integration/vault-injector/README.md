# Vault Agent Injector
- [Installation documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/injector/installation)
- [Vault Injector annotations](https://developer.hashicorp.com/vault/docs/platform/k8s/injector/annotations)
- [Rosemary Wang's blog/example](https://www.hashicorp.com/blog/refresh-secrets-for-kubernetes-applications-with-vault-agent)


## Installation
### Pre-requisite
> [!IMPORTANT]
> For GKE, you will require the PD CSI driver enabled (I assume you will require something similar for other cloud providers).  So make sure you have this enabled!

In your `terraform.tfvars` file, make sure you have the following config set to `true`:
```
addons_config = {
  gce_pd_csi_driver_enabled = true
}
```

### Install Injector ONLY
This will likely be the mode for most users as they want to connect to an external Vault instance/cluster:
```
helm install vault hashicorp/vault \
  --set="global.externalVaultAddr=[YOUR_VAULT_ADDR:PORT]" \
  --set="injector.enabled=true"
```

### Install Injector with Vault
For the demo below, we will deploy a single-instance Vault server in dev mode:
```
helm install vault hashicorp/vault \
  --set="server.dev.enabled=true" \
  --set="injector.enabled=true"
```

> [!NOTE]
> My GKE cluster deployment is built on spot nodes which may be replaced as early as every ~24hrs.  If you want your configs and secrets to be more persistent, I recommend connecting to an external Vault instance 


## Vault Injector demo
The following is a slightly-modified version of the sample found [here](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar)

### Create KV secret
- exec into your Vault instance/pod:
```
vault secrets enable -path=internal kv-v2

vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
```

### Setup Kubernetes auth
- exec into your Vault instance/pod:
```
vault auth enable kubernetes

vault write auth/kubernetes/config \
      kubernetes_host="https://[KUBERNETES_ADDR]:443"
```

For the *KUBERNETES_ADDR*, I used the private endpoint.  You can use the Google Cloud console, but I queried it with the following (adjust values as it pertains to your cluster/zone setup):
```
gcloud container clusters describe playground \
  --zone=northamerica-northeast1-c \
  --format="value(privateClusterConfig.privateEndpoint)"
```

### Configure Kubernetes auth policy
- exec into your Vault instance/pod:
```
vault policy write internal-app - <<EOF
path "internal/data/database/config" {
   capabilities = ["read"]
}
EOF
```

```
vault write auth/kubernetes/role/internal-app \
      bound_service_account_names=internal-app \
      bound_service_account_namespaces=default \
      policies=internal-app \
      ttl=24h
```

### Deploying app
- create Kubernetes service account:
```
kubectl create sa internal-app
```

#### Basic example (v1)
```
kubectl apply -f sample-app_v1.yaml
```

In this deployment, the KV secret will be mounted at `/vault/secrets/database-config.txt` but you may find that the format is not what you desire, so you can apply the secret to a template so that it is structured just the way you like it!

You can also exec into your Vault instance/pod and update your secret, and you should see it updated in about 300s (but you can [configure the frequency which the sidecar agent polls vault for KV secret updates](https://developer.hashicorp.com/vault/docs/platform/k8s/injector/annotations#vault-hashicorp-com-template-static-secret-render-interval))

#### Templated example (v2)
```
kubectl apply -f sample-app_v2.yaml
```

In this deployment, the KV secret will be mounted at `/vault/secrets/database-config.txt`, but the format of the secret will followe the template provided.

In addition, I've added an extra annotation to issue the command, `kill -SIGTERM 1` (where 1 is the PID of the app) once a change in the KV secret is detected.
