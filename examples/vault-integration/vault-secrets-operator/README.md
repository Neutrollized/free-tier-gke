# Vault Secrets Operator (VSO)

This following is a (modified) basic version of the example from the [HashiCorp developer](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator) site.  

- [Vault Secrets Operator API reference](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/api-reference#api-reference)


## Installation
### Install Vault (Dev) Server
For the demo below, we will deploy a single-instance Vault server in dev mode:
```
helm install vault hashicorp/vault \
  --set="server.dev.enabled=true" \
  --set="injector.enabled=false"
```

### Install VSO
```
helm install vault-secrets-operator hashicorp/vault-secrets-operator \
  -n vault-secrets-operator-system \
  --create-namespace \
  --values values/vso-values.yaml
```


## Vault Config
### Kubernetes Auth Method
```
vault auth enable -path gke kubernetes
```

```
vault write auth/gke/config \
  kubernetes_host="https://192.168.0.2:443"
```

- you can find your GKE's private endpoint with this command (adjust your cluster name and zone accordingly):
```
gcloud container clusters describe playground \
  --zone=northamerica-northeast1-c \
  --format="value(privateClusterConfig.privateEndpoint)"
```

- using the `secret/` kv-v2 store that comes with dev mode (you're free to create your own)
```sh
tee /tmp/kv-read.json <<EOF
path "secret/data/webapp/config" {
   capabilities = ["read", "list"]
}
EOF

vault policy write kv-read /tmp/kv-read.json
```

- Kubernetes auth method create/update role [documentation](https://developer.hashicorp.com/vault/api-docs/auth/kubernetes#create-update-role)
```
vault write auth/gke/role/kvreadrole \
   bound_service_account_names=demo-static-app \
   bound_service_account_namespaces=app \
   policies=kv-read \
   audience=vault \
   ttl=24h
```

### Vault Static Secrets
```
vault kv put secret/webapp/config username="static-user" password="static-password"
```

## Vault Secrets Operator Demo
```
kubectl create ns app

kubectl apply -f vaultauth-app.yaml
kubectl apply -f vaultstaticsecret-app.yaml
kubectl apply -f app.yaml
```

You can go into Vault and then change the secret's password (and/or username) and after about 30s (per [`spec.refreshAfter`](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/api-reference#vaultstaticsecretspec)), it should get reflected in the Kubernetes secret and the app. 
