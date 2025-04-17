# Workload Identity

Here's a great [YouTube video](https://www.youtube.com/watch?v=4OzbPaJCUr8&ab_channel=GoogleCloudTech) from Google developer advocate, Kaslin Fields, that describes how Workload Identity works in GKE and how it increases your security posture.

**NOTE:** just because Workload Identity is enabled doesn't mean you'll be using it.  You'll need to have a service account on the Kubernetes side as well as on the GCP side so that you can associate the two.

Example below based on [Workload Identity guide](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)

- KSA = Kubernetes service account
- GSA = GCP service account (via IAM)


## Syntax
```sh
gcloud iam service-accounts create GSA_NAME
```

```sh
kubectl create serviceaccount KSA_NAME \
  --namespace NAMESPACE
```

- allow Kubernetes service account to impersonate the GCP service account by adding IAM policy binding between the two:
```sh
gcloud iam service-accounts add-iam-policy-binding GSA_NAME@GSA_PROJECT_ID.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:PROJECT_ID.svc.id.goog[NAMESPACE/KSA_NAME]"
```

- annotate Kubernetes service account with email address of GCP service account:
```sh
kubectl annotate serviceaccount KSA_NAME \
  --namespace NAMESPACE \
  iam.gke.io/gcp-service-account=GSA_NAME@PROJECT_ID.iam.gserviceaccount.com
```

- update `serviceAccountName` in Pod spec to use new KSA

**NOTE** GSA does not have to be in the same project as the GKE cluster (i.e. can access GCP APIs from other projects if needed)


### Example
- I will be using a separate namespace in this example
```sh
kubectl create ns wi-test
```

```sh
kubectl create serviceaccount simple-wi-ksa -n wi-test
```

- if you deployed the cluster from my blueprint, a Google service account called "simple-wi-gsa" should arleady be created for you, otherwise please create one first before continuing onto the next step
```sh
gcloud iam service-accounts add-iam-policy-binding simple-wi-gsa@my-project.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:my-project.svc.id.goog[wi-test/simple-wi-ksa]"
```

```sh
kubectl annotate serviceaccount simple-wi-ksa \
  --namespace wi-test \
  iam.gke.io/gcp-service-account=simple-wi-gsa@my-project.iam.gserviceaccount.com
```

- you can confirm the changes with `kubectl describe serviceaccount simple-wi-ksa -n wi-test`:
```console
Name:                simple-wi-ksa
Namespace:           wi-test
Labels:              <none>
Annotations:         iam.gke.io/gcp-service-account: simple-wi-gsa@my-project.iam.gserviceaccount.com
Image pull secrets:  <none>
Mountable secrets:   simple-wi-ksa-token-th4tc
Tokens:              simple-wi-ksa-token-th4tc
Events:              <none>
```

- deploy container
```sh
kubectl apply -f wi-test.yaml
```

- verify setup by checking node metadata server:
```sh
kubectl exec workload-identity-test -n wi-test -- curl -s -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email
```
