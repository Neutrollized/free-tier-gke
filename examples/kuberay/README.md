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


## View Ray logs
Because we also enabled Ray logging, you can now [query your Ray logs in Cloud Logging](https://docs.cloud.google.com/kubernetes-engine/docs/add-on/ray-on-gke/how-to/collect-view-logs-metrics#view_ray_logs).


## Cleanup
`kubectl ray delete raycluster-cpu` or `kubectl delete -f raycluster-cpu`

> [!NOTE]
> The command to delete a cluster is just `kubectl ray delete [RAY_CLUSTER_NAME]`, and NOT `kubectl ray delete cluster [RAY_CLUSTER_NAME]`
> I'm not a fan of this because it's not consistent with the create cluster command, so if you used the latter and got an error, that's because it thought you were trying to delete two clusters (where one of them was named `cluster`)

