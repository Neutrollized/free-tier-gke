# Velero

(It used to be called Heptio prior to being acquired by VMware)


## Requirements
- [Velero CLI](https://velero.io/docs/main/velero-install/)
- [Velero plugin for GCP](https://github.com/vmware-tanzu/velero-plugin-for-gcp)

> [!IMPORTANT]
> You will not be able to run this example on an e2-medium machine type.
> I recommend a 4 vCPU node machine type such as the e2-standard-4 or better.


## Setup
Before we run the `velero install` command, we'll need to provision some resources and service accounts first: 

### GCS Bucket
```
gcloud storage buckets create gs://${GCS_BUCKET} \
  --location=${GCS_BUCKET_LOCATION}
```

### IAM Service Account
- Google Cloud Service Account (GSA):
```
gcloud iam service-accounts create velero-sa \
  --description="Service Account for Velero"
```

- create custom role for Velero (principle of least privilege):
```
ROLE_PERMISSIONS=(
  compute.disks.get
  compute.disks.create
  compute.disks.createSnapshot
  compute.projects.get
  compute.snapshots.get
  compute.snapshots.create
  compute.snapshots.useReadOnly
  compute.snapshots.delete
  compute.snapshots.setLabels
  compute.zones.get
  storage.objects.create
  storage.objects.delete
  storage.objects.get
  storage.objects.list
  iam.serviceAccounts.signBlob
)

gcloud iam roles create velero.server \
  --project ${PROJECT_ID} \
  --title "Velero Server" \
  --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"
```


- assign custom Velero Server role to GSA:
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member "serviceAccount:velero-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role projects/${PROJECT_ID}/roles/velero.server \
  --condition None

gsutil iam ch serviceAccount:velero-sa@${PROJECT_ID}.iam.gserviceaccount.com:objectAdmin gs://${GCS_BUCKET}
```

> [!WARNING]
> Workload Identity currently not working as documented so until I get that resolved,
> this example will require you to create a credentials JSON to be turned in to a k8s secret


### Velero install
- using GCP service account key:
```
velero install \
    --provider gcp \
    --plugins velero/velero-plugin-for-gcp:v1.13.1 \
    --bucket ${GCS_BUCKET} \
    --secret-file /path/to/serviceaccount/credentials.json
```

- sample output (trimmed for brevity):
```console
...
...
CustomResourceDefinition/backuprepositories.velero.io: created
CustomResourceDefinition/backups.velero.io: created
CustomResourceDefinition/backupstoragelocations.velero.io: created
CustomResourceDefinition/deletebackuprequests.velero.io: created
CustomResourceDefinition/downloadrequests.velero.io: created
CustomResourceDefinition/podvolumebackups.velero.io: created
CustomResourceDefinition/podvolumerestores.velero.io: created
CustomResourceDefinition/restores.velero.io: created
CustomResourceDefinition/schedules.velero.io: created
CustomResourceDefinition/serverstatusrequests.velero.io: created
CustomResourceDefinition/volumesnapshotlocations.velero.io: created
CustomResourceDefinition/datadownloads.velero.io: created
CustomResourceDefinition/datauploads.velero.io: created
Waiting for resources to be ready in cluster...
Namespace/velero: already exists, proceeding
Namespace/velero: created
ClusterRoleBinding/velero: created
ServiceAccount/velero: created
BackupStorageLocation/default: created
VolumeSnapshotLocation/default: created
Deployment/velero: created

No secret file was specified, no Secret created.

Velero is installed! ⛵ Use 'kubectl logs deployment/velero -n velero' to view the status.
```

## Backup
```
velero backup create nginx-backup --selector app.kubernetes.io/name=nginx
```


## Cleanup
```
velero uninstall

gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
  --role projects/${PROJECT_ID}/roles/velero.server \
  --member "serviceAccount:velero-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --condition None

gcloud iam service-accounts delete velero-sa@${PROJECT_ID}.iam.gserviceaccount.com
```
