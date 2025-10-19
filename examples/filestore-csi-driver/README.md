# Filestore CSI Driver
This example very closely follows the example found [here](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/filestore-csi-driver#access_a_volume_using_the)


## Deploying Example
- verify Filestore CSI driver is enabled
```
kubectl get storageclass
```

- apply the StorageClass
```
kubectl apply -f filestore-example-class.yaml
```

> [!NOTE]
> `volumeBindingMode` here is set to `WaitForFirstConsumer`.  The default is `Immediate`, which provisions the [Filestore](https://cloud.google.com/filestore) instance (i.e. the PV) once the PVC is created (next step).  With `WaitForFirstConsumer`, the Filestore will be provisioned once there are pods that will utilize the PVC (which will take ~2 min)

- apply the PVC
```
kubectl apply -f pvc-example.yaml
```

- apply the deployment
```
kubectl apply -f web-server-example.yaml
```

## Cleanup
```
kubectl delete -f web-server-example.yaml
kubectl delete -f pvc-example.yaml
kubectl delete -f filestore-example-class.yaml
```
- it will take ~2 min for the Filestore instance to get destroyed
