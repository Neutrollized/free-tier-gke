# Secrets Store CSI Driver

## Introduction
Secrets management is undoubtedly one of the most important pieces in software development today.  The Secrets Store CSI Driver is an *active* open source project that aims to provide secrets management for Kubernetes and supports providers for Google Cloud Platform, Amazon AWS, Microsoft Azure, and HashiCorp Vault.  The GCP provider also uses [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) which is particularly favorable in many enterprise settings where `constraints/iam.disableServiceAccountKeyCreation` is often enforced (not having long-lived credentials JSON service account key files is also preferred/recommended from a security perspective).

This makes the Secrets Store CSI Driver a versatile secrets management tool in the Kubernetes ecosystem and is recommended for use with Anthos.

### Open-source or Google-managed?
The instructions I provided below is for setting up the open source version, but you can actually toggle a setting which will enable a Google-managed version of the same CSI driver for you.  It's called the [Secret Manager add-on for GKE](https://cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component), and as far as I can tell, it's the same thing except it's managed and version of the driver is pinned/set by Google.


## Setup
### Installing CSI Driver
It is recommended to use its helm chart for installation.  List of configurable options can be found [here](https://github.com/kubernetes-sigs/secrets-store-csi-driver/tree/main/charts/secrets-store-csi-driver#configuration).  A notable feature that is still in **alpha** stage is [secrets auto-rotation](https://secrets-store-csi-driver.sigs.k8s.io/topics/secret-auto-rotation.html)

- adding Secrets Store CSI Driver helm repo & listing available versions
```
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm search repo secrets-store-csi-driver/secrets-store-csi-driver --versions
```

- installing version 1.3.4 (latest at time of writing)
```
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system --version 1.3.4
```

#### Verify Install:
You should see output similar to the following for `kubectl get pods -n kube-system`:
```console
...
csi-secrets-store-secrets-store-csi-driver-ddg5q           3/3     Running   0          6m49s
csi-secrets-store-secrets-store-csi-driver-mv7vw           3/3     Running   0          6m49s
csi-secrets-store-secrets-store-csi-driver-wfnbb           3/3     Running   0          6m49s
...
```

You should see outputs similar to the following for `kubectl get crd`:
```console
...
secretproviderclasses.secrets-store.csi.x-k8s.io                   2023-06-24T13:18:13Z
secretproviderclasspodstatuses.secrets-store.csi.x-k8s.io          2023-06-24T13:18:13Z
...
```

### Install Google Cloud Provider
The following creates the required Kubernetes service accounts, RBAC and deploy a GCP provider DaemonSet.
```sh
git clone https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp
cd secrets-store-csi-driver-provider-gcp

helm upgrade --install secrets-store-csi-driver-provider-gcp charts/secrets-store-csi-driver-provider-gcp
```

or

```sh
curl -L0 https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/main/deploy/provider-gcp-plugin.yaml -o provider-gcp-plugin.yaml

kubectl apply -f provider-gcp-plugin.yaml
```

#### Verify Install:
You should see output similar to the following for `kubectl get pods -n kube-system`:
```console
...
csi-secrets-store-provider-gcp-klj67                       1/1     Running   0          15s
csi-secrets-store-provider-gcp-n5rj7                       1/1     Running   0          15s
csi-secrets-store-provider-gcp-vzwp5                       1/1     Running   0          15s
...
```


## Sample Usage - GCP
Since the GCP provider utilizes Workload Identity to access secrets from [Secrets Manager](https://cloud.google.com/secret-manager), some setup will be required to create the appropriate accounts and mapping.

**ATTENTION:** Please note the **gsa** and **ksa** suffixes in the service account names for differentiation between a Google service account (GSA) and Kubernetes service account (KSA).  It is recommended that a naming convention that can easily identify the mapping between the GSA and KSA be used.

- create Google service account and Kubernetes service account
```
gcloud iam service-accounts create secret-csi-wi-gsa \
  --description="Workload Identity SA for Secret Store CSI Driver"

kubectl create serviceaccount secret-csi-wi-ksa
```

- assign the appropriate role to GSA (for accessing Secrets Manager secrets, this is typically the **Secret Accessor** role)
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --role roles/secretmanager.secretAccessor \
  --member "serviceAccount:secret-csi-wi-gsa@${PROJECT_ID}.iam.gserviceaccount.com"
```

- assign your KSA the [Workload Identity User](https://cloud.google.com/iam/docs/understanding-roles#iam.workloadIdentityUser) role which gives it the permission to impersonate your GSA
```
gcloud iam service-accounts add-iam-policy-binding secret-csi-wi-gsa@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[default/secret-csi-wi-ksa]"
```

- annotate the KSA
```
kubectl annotate serviceaccount secret-csi-wi-ksa \
  iam.gke.io/gcp-service-account=secret-csi-wi-gsa@${PROJECT_ID}.iam.gserviceaccount.com
```


### Sample application
- enable Secrets Manager API:
```
gcloud services enable secretmanager.googleapis.com
```

- create Secrets Manager secret from file:
```
gcloud secrets create myappsecret --replication-policy=automatic --data-file=secret.data
```

- update & create Secrets Store secret
```
kubectl apply -f app-secrets.yaml
```

**NOTE:** you can find available secret versions via `gcloud secrets versions list [SECRET_NAME]` or if you prefer the latest version, it can be set to `latest`. The exact manifest YAML can be templated with your preferred tool of choice.


- deploy app, referencing secret and CSI driver
```
kubectl apply -f mypod.yaml
```

The secret is fetched and mounted in a read-only file located at `/var/secrets/myappsecret.txt` and ready for consumption, which you can confirm with:
```
kubectl exec mypod -- cat /var/secret/myappsecret.txt
```


## Cleanup
```
kubectl delete -f mypod.yaml
kubectl delete -f app-secrets.yaml

gcloud secrets delete myappsecret

gcloud iam service-accounts remove-iam-policy-binding secret-csi-wi-gsa@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[default/secret-csi-wi-ksa]"

gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
  --role roles/secretmanager.secretAccessor \
  --member "serviceAccount:secret-csi-wi-gsa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts delete secret-csi-wi-gsa@${PROJECT_ID}.iam.gserviceaccount.com
```
