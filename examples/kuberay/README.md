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
kubectl apply -f raycluster-cpu.yaml
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

## Sample RayJobs
### Demo Python job
I have included a sample `fake_job.py` for you to submit to the Ray cluster for execution, but before you can do that, you will first need to start a session (this simply just forwards local ports to your Ray cluster):
```
kubectl ray session raycluster-cpu
```

> [!NOTE]
> If you exposed your head service endpoint (i.e. via ingress), then you do not need to run `kubectl ray sessions [RAY_CLUSTER_NAME]`

- Submit your Ray job:
```
ray job submit \
  --working-dir=. \
  --address http://localhost:8265 -- python fake_job.py
```

> [!NOTE]
> You can check out your Ray dashboard at [http://localhost:8265](http://localhost:8265)

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
To run:
```
kubectl apply -f rayjob-pytorch-mnist.yaml
```

This is a modified version of [this KubeRay sample job](https://github.com/ray-project/kuberay/tree/master/ray-operator/config/samples/pytorch-mnist). I am deploying to my existing Ray cluster rather than have the job spin one up, which is a common use case with [Kueue](https://kueue.sigs.k8s.io/docs/tasks/run/rayjobs/).

> [!NOTE]
> This Python code for this particular example does not save the model anywhere -- it's merely trains -- used to verify that a Ray cluster can coordinate workers and report multiple metrics.
> You should also save any artifacts to an external storage such as a GCS bucket.

- sample output:
```console
2026-01-11 12:13:17,288 INFO cli.py:41 -- Job submission server address: http://raycluster-cpu-head-svc.default.svc.cluster.local:8265
2026-01-11 12:13:17,702 SUCC cli.py:65 -- -------------------------------------------------------
2026-01-11 12:13:17,703 SUCC cli.py:66 -- Job 'rayjob-pytorch-mnist-mh22c' submitted successfully
2026-01-11 12:13:17,703 SUCC cli.py:67 -- -------------------------------------------------------
2026-01-11 12:13:17,703 INFO cli.py:291 -- Next steps
2026-01-11 12:13:17,703 INFO cli.py:292 -- Query the logs of the job:
2026-01-11 12:13:17,703 INFO cli.py:294 -- ray job logs rayjob-pytorch-mnist-mh22c
2026-01-11 12:13:17,703 INFO cli.py:296 -- Query the status of the job:
2026-01-11 12:13:17,703 INFO cli.py:298 -- ray job status rayjob-pytorch-mnist-mh22c
2026-01-11 12:13:17,703 INFO cli.py:300 -- Request the job to be stopped:
2026-01-11 12:13:17,703 INFO cli.py:302 -- ray job stop rayjob-pytorch-mnist-mh22c
2026-01-11 12:13:19,541 INFO cli.py:41 -- Job submission server address: http://raycluster-cpu-head-svc.default.svc.cluster.local:8265
...
...
Test Epoch 9:   0%|          | 0/313 [00:00<?, ?it/s]
(RayTrainWorker pid=1131, ip=10.0.1.21)
Test Epoch 9:   7%|▋         | 23/313 [00:00<00:01, 228.59it/s]
(RayTrainWorker pid=1158, ip=10.0.2.12)
Test Epoch 9:  97%|█████████▋| 305/313 [00:01<00:00, 217.00it/s]
Test Epoch 9: 100%|██████████| 313/313 [00:01<00:00, 223.70it/s]
(RayTrainWorker pid=1158, ip=10.0.2.12) Reporting training result 10: TrainingReport(checkpoint=None, metrics={'loss': 0.3590725670083643, 'accuracy': 0.8724}, validation_spec=None)
Training result: Result(metrics=None, checkpoint=None, error=None, path='/home/ray/ray_results/ray_train_run-2026-01-11_12-15-38', metrics_dataframe=None, best_checkpoints=[], _storage_filesystem=<pyarrow._fs.LocalFileSystem object at 0x7b81046f0c30>)
(RayTrainWorker pid=1158, ip=10.0.2.12) [Gloo] Rank 0 is connected to 1 peer ranks. Expected number of connected peer ranks is : 1
(RayTrainWorker pid=1131, ip=10.0.1.21)
Train Epoch 9:  99%|█████████▉| 1864/1875 [00:26<00:00, 71.61it/s] [repeated 39x across cluster]
(RayTrainWorker pid=1158, ip=10.0.2.12)
Train Epoch 9: 100%|█████████▉| 1873/1875 [00:26<00:00, 71.64it/s]
Train Epoch 9: 100%|██████████| 1875/1875 [00:26<00:00, 69.58it/s]
(RayTrainWorker pid=1158, ip=10.0.2.12)
Test Epoch 9:   0%|          | 0/313 [00:00<?, ?it/s]
(RayTrainWorker pid=1131, ip=10.0.1.21)
Test Epoch 9:  88%|████████▊ | 276/313 [00:01<00:00, 194.93it/s] [repeated 23x across cluster]
(RayTrainWorker pid=1131, ip=10.0.1.21)
Test Epoch 9:  95%|█████████▍| 297/313 [00:01<00:00, 198.18it/s]
Test Epoch 9: 100%|██████████| 313/313 [00:01<00:00, 211.06it/s]
(RayTrainWorker pid=1131, ip=10.0.1.21) Reporting training result 10: TrainingReport(checkpoint=None, metrics={'loss': 0.3736847228409288, 'accuracy': 0.86}, validation_spec=None)
2026-01-11 12:23:42,366 SUCC cli.py:65 -- ------------------------------------------
2026-01-11 12:23:42,366 SUCC cli.py:66 -- Job 'rayjob-pytorch-mnist-mh22c' succeeded
2026-01-11 12:23:42,366 SUCC cli.py:67 -- ------------------------------------------
```


## View Ray logs
Because we also enabled Ray logging, you can now [query your Ray logs in Cloud Logging](https://docs.cloud.google.com/kubernetes-engine/docs/add-on/ray-on-gke/how-to/collect-view-logs-metrics#view_ray_logs).


## Cleanup
`kubectl ray delete raycluster-cpu` or `kubectl delete -f raycluster-cpu`

> [!NOTE]
> The command to delete a cluster is just `kubectl ray delete [RAY_CLUSTER_NAME]`, and NOT `kubectl ray delete cluster [RAY_CLUSTER_NAME]`
> I'm not a fan of this because it's not consistent with the create cluster command, so if you used the latter and got an error, that's because it thought you were trying to delete two clusters (where one of them was named `cluster`)

