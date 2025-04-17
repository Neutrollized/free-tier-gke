# README
Follows documentation for [restricting deployment to a GKE namespace](https://cloud.google.com/deploy/docs/securing/sa-by-namespace)

## Creating a Namespace-restricted Service Account
```
gcloud iam service-accounts create store-user
```

- give the service account the Kubernetes Cluster Viewer role (`roles/container.clusterViewer`) which allows the SA access to the cluster **only**:
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:store-user@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/container.clusterViewer
```

- actual cluster permissions will be defined by the following, which you will have to apply (i.e. `kubectl apply -f serviceaccount.yaml`):
```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: store-user-role
  namespace: store-ns
rules:
  - apiGroups: ["", "apps", "extensions", "gateway.networking.k8s.io"]
    resources: ["*"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: store-user-role-binding
  namespace: store-user-ns
subjects:
  - kind: User
    name: store-user@${PROJECT_ID}.iam.gserviceaccount.com
roleRef:
  kind: Role
  name: store-user-role
  apiGroup: rbac.authorization.k8s.io
```


## How-to Conneect to GKE
Follows documentation for [authenticating to the Kubernetes API server](https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication#environments-without-gcloud)

You will need a `kubeconfig.yaml` with your GKE's cluster, users and contexts as well as the corresponding credentials JSON.

### Credentials JSON
```
gcloud iam service-accounts keys create gsa-key.json \
  --iam-account=store-user@${PROJECT_ID}.iam.gserviceaccount.com
```

### `kubeconfig.yaml`
- you can get the ENDPOINT with:
```
gcloud container clusters describe playground \
    --zone=northamerica-northeast1-c \
    --format="value(endpoint)" 
```
or from `kubectl cluster-info`

- you can get the CA_CERT with:
```
gcloud container clusters describe playground \
    --zone=northamerica-northeast1-c \
    --format="value(masterAuth.clusterCaCertificate)" 
```

```yaml
---
apiVersion: v1
kind: Config
clusters:
- name: playground
  cluster:
    server: https://${ENDPOINT}
    certificate-authority-data: ${CA_CERT}
users:
- name: store-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - --use_application_default_credentials
      command: gke-gcloud-auth-plugin
      installHint: Install gke-gcloud-auth-plugin for kubectl by following
        https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin
      provideClusterInfo: true
contexts:
- context:
    cluster: playground
    user: store-user
  name: playground-store
current-context: playground-store
```

### Export ENV VARs
```sh
export KUBECONFIG=/path/to/kubeconfig.yaml
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/gsa-key.json
```


## Validating Access
Since your user would only have permissions in the **store-ns** namespace, trying to run commands anywhere else should produce an error:

- example `kubectl get pods` (in **default** namespace):
```console
Error from server (Forbidden): pods is forbidden: User "store-user@my-project.iam.gserviceaccount.com" cannot list resource "pods" in API group "" in the namespace "default": requires one of ["container.pods.list"] permission(s).
```

- example `kubectl apply -f site.yaml` (which deploys to **site-ns** namespace):
```console
Error from server (Forbidden): error when retrieving current configuration of:
Resource: "apps/v1, Resource=deployments", GroupVersionKind: "apps/v1, Kind=Deployment"
Name: "site-v1", Namespace: "site-ns"
from server for: "site.yaml": deployments.apps "site-v1" is forbidden: User "store-user@my-project.iam.gserviceaccount.com" cannot get resource "deployments" in API group "apps" in the namespace "site-ns": requires one of ["container.deployments.get"] permission(s).
Error from server (Forbidden): error when retrieving current configuration of:
Resource: "/v1, Resource=services", GroupVersionKind: "/v1, Kind=Service"
Name: "site-v1", Namespace: "site-ns"
from server for: "site.yaml": services "site-v1" is forbidden: User "store-user@my-project.iam.gserviceaccount.com" cannot get resource "services" in API group "" in the namespace "site-ns": requires one of ["container.services.get"] permission(s).
```
