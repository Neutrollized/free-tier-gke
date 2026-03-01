# KubeRay / Ray

> [!IMPORTANT]
> To run this example, may sure you **enable the Ray Operator** in the add-ons config:
> ```
> addons_config = {
>   ray_operator_enabled = true
> }
> ```
> This will install the necessary CRDs.
>
> It is also recommended that you use *e2-standard-4* (or better) machine types for this example. 


## Prerequisites
Install [Krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/), a plugin manager for `kubectl` (you can also install using Homebrew if you're on a Mac)

Install the Ray plugin:
```
kubectl krew update
kubectl krew install ray
```

You will need the `ray[default]` Python package for general Python applications and `ray[data,train,tune,serve]` for ML applications. You will need this `ray` binary in order to submit Ray jobs.


## Setup Ray cluster
While AI/ML workloads have become an increasingly popular use case for Ray, it also runs and scales Python applications very well. The cluster and demo job below is going to be **CPU only** so you can get a feel for how Ray works without breaking the bank with GPU-enabled nodes.

> [!NOTE]
> I have provided a Ray cluster configuration which I encourage you to take a look at before applying. You may also want to adjust your `nodeSelector` instance type to match the one you're using. 
> In my example, I need 5 CPUs and 10Gi of memory for the head node and 2 workers nodes, so I'm using *e2-standard-4* machine types, but you can use an *e2-standard-2* and lower the CPU, memory and replica worker counts if you really want to keep costs to a minimum.

CPU-only Ray cluster config:
```
task kuberay:simple PROJECT_ID=myproject-123
```

Optionally, you can also use the following `kubectl ray` command:
```
kubectl ray create cluster raycluster-cpu \
  --head-cpu=1 \
  --head-memory=2Gi \
  --worker-replicas=2 \
  --worker-cpu=2 \
  --worker-memory=4Gi \
  --worker-node-selectors="node.kubernetes.io/instance-type=e2-standard-4"
```
(but I prefer declarative nature of YAML)

> [!NOTE]
> If you wish to save your ML model and checkpoints in a GCS bucket,
> deploy the Ray cluster with Workload Identity Federation

```
task kuberay:wif PROJECT_ID=myproject-123
``````

## Sample RayJobs
### Demo Python job
I have included a sample `fake_job.py` for you to submit to the Ray cluster for execution, but before you can do that, you will first need to start a session (this simply just forwards local ports to your Ray cluster):
```
kubectl ray session raycluster-cpu
```

- Submit your Ray job:
```
ray job submit \
  --working-dir=. \
  --address http://localhost:8265 -- python fake_job.py
```

> [!TIP]
> You can check out your Ray dashboard at [http://localhost:8265](http://localhost:8265)

> [!NOTE]
> If you find that your job isn't start, check `kubectl get rayjob`
> to see if another job with the same name already exists, if so you must delete it
> or give the job you want to run a new/different name

- results with `@ray.remote(num_cpus=0.25)`:
```console
...
...
✅ Finished processing 20 tasks in 11.90 seconds.
--- Results ---
Task 0 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 1 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 2 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 3 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 4 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 5 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 6 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 7 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 8 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 9 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 10 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 11 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 12 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 13 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 14 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 15 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 16 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 17 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 18 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 19 processed on raycluster-cpu-worker-group-worker-qnwxj
...
```

- results with `@ray.remote(num_cpus=2)`:
```console
...
...
✅ Finished processing 20 tasks in 52.43 seconds.
--- Results ---
Task 0 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 1 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 2 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 3 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 4 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 5 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 6 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 7 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 8 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 9 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 10 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 11 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 12 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 13 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 14 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 15 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 16 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 17 processed on raycluster-cpu-worker-group-worker-qnwxj
Task 18 processed on raycluster-cpu-worker-group-worker-ssn9g
Task 19 processed on raycluster-cpu-worker-group-worker-qnwxj
...
```

### Demo PyTorch MNIST training job
> [!IMPORTANT]
> Please update the `GCP_BUCKET` env vars in `Taskfile.yaml` and `rayjob-pytorch-mnist-wif` first :)

To run:
```
kubectl apply -f rayjob-pytorch-mnist.yaml
```
> [!NOTE]
> This Python code for this particular example does not save the model anywhere. It merely trains and used to verify that a Ray cluster can coordinate workers and report multiple metrics.
> If you want to save any artifacts to an external storage such as a GCS bucket run the job below instead

```
kubectl apply -f rayjob-pytorch-mnist-wif.yaml
```

These are modified versions of [this KubeRay sample job](https://github.com/ray-project/kuberay/tree/master/ray-operator/config/samples/pytorch-mnist). I am deploying to my existing Ray cluster rather than have the job spin one up, which is a common use case with [Kueue](https://kueue.sigs.k8s.io/docs/tasks/run/rayjobs/).

- sample output:
```console
2026-02-27 19:10:52,297 INFO cli.py:41 -- Job submission server address: http://raycluster-cpu-wif-head-svc.default.svc.cluster.local:8265
2026-02-27 19:10:52,671 SUCC cli.py:65 -- -----------------------------------------------------------
2026-02-27 19:10:52,671 SUCC cli.py:66 -- Job 'rayjob-pytorch-mnist-wif-f4skt' submitted successfully
2026-02-27 19:10:52,671 SUCC cli.py:67 -- -----------------------------------------------------------
2026-02-27 19:10:52,671 INFO cli.py:291 -- Next steps
2026-02-27 19:10:52,671 INFO cli.py:292 -- Query the logs of the job:
2026-02-27 19:10:52,671 INFO cli.py:294 -- ray job logs rayjob-pytorch-mnist-wif-f4skt
2026-02-27 19:10:52,671 INFO cli.py:296 -- Query the status of the job:
2026-02-27 19:10:52,671 INFO cli.py:298 -- ray job status rayjob-pytorch-mnist-wif-f4skt
2026-02-27 19:10:52,671 INFO cli.py:300 -- Request the job to be stopped:
2026-02-27 19:10:52,672 INFO cli.py:302 -- ray job stop rayjob-pytorch-mnist-wif-f4skt
2026-02-27 19:10:54,867 INFO cli.py:41 -- Job submission server address: http://raycluster-cpu-wif-head-svc.default.svc.cluster.local:8265
2026-02-27 19:10:52,366 INFO job_manager.py:579 -- Runtime env is setting up.
...
...
GcsFileSystem object at 0x7f86246e92f0>)
Final checkpoint saved to: mybucket/fashion_mnist_ray_experiment/checkpoint_2026-02-27_19-21-51.406550
(RayTrainWorker pid=2325, ip=10.0.1.15) [Gloo] Rank 1 is connected to 1 peer ranks. Expected number of connected peer ranks is : 1
(RayTrainWorker pid=2312, ip=10.0.0.136)
Train Epoch 9: 100%|██████████| 1875/1875 [00:36<00:00, 51.24it/s] [repeated 47x across cluster]
(RayTrainWorker pid=2312, ip=10.0.0.136)
Test Epoch 9:   0%|          | 0/313 [00:00<?, ?it/s]
(RayTrainWorker pid=2325, ip=10.0.1.15)
Test Epoch 9:  91%|█████████ | 285/313 [00:01<00:00, 193.75it/s] [repeated 26x across cluster]
(RayTrainWorker pid=2325, ip=10.0.1.15) Checkpoint successfully created at: Checkpoint(filesystem=gcs, path=mybucket/fashion_mnist_ray_experiment/checkpoint_2026-02-27_19-21-51.406550)
(RayTrainWorker pid=2325, ip=10.0.1.15) Reporting training result 10: TrainingReport(checkpoint=Checkpoint(filesystem=gcs, path=mybucket/fashion_mnist_ray_experiment/checkpoint_2026-02-27_19-21-51.406550), metrics={'loss': 0.36814677305876636, 'accuracy': 0.8656}, validation_spec=None)
2026-02-27 19:22:01,567 SUCC cli.py:65 -- ----------------------------------------------
2026-02-27 19:22:01,567 SUCC cli.py:66 -- Job 'rayjob-pytorch-mnist-wif-f4skt' succeeded
2026-02-27 19:22:01,568 SUCC cli.py:67 -- ----------------------------------------------
```


## View Ray logs
Because we also enabled Ray logging, you can now [query your Ray logs in Cloud Logging](https://docs.cloud.google.com/kubernetes-engine/docs/add-on/ray-on-gke/how-to/collect-view-logs-metrics#view_ray_logs).


## Cleanup
`kubectl ray delete raycluster-cpu` or `kubectl delete -f raycluster-cpu`

> [!NOTE]
> The command to delete a cluster is just `kubectl ray delete [RAY_CLUSTER_NAME]`, and NOT `kubectl ray delete cluster [RAY_CLUSTER_NAME]`
> I'm not a fan of this because it's not consistent with the create cluster command, so if you used the latter and got an error, that's because it thought you were trying to delete two clusters (where one of them was named `cluster`)

