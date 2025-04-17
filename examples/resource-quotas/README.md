# Resource Quotas
[Resource quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/) are a simple and effective way of reducing "[noisy neighbors](https://kubernetes.io/docs/concepts/security/multi-tenancy/)" is by putting constraints on the aggregate resources a namespace can acquire/use.

In addition to CPU and memory constraints, you can also set storage quotas, object count quotas, etc.

## Example
- create namespace, "devteam" and apply quota:
```sh
kubectl apply -f cpu-mem-quota.yaml
```

- deploy NGINX workload to namespace:
```sh
kubectl apply -f nginx-deploy.yaml -n devteam
```

At this point, you should have 2 replicas of an NGINX pod because the resource I've allocated still falls within the quota limits.  Now, let's see what happens when we scale up the number of repicas...

- scale up
```sh
kubectl scale --replicas=3 deployment/nginx -n devteam
```

You shouldn't see a third NGINX pod in the devteam namespace, but you won't necessarily get an error in your terminal either.  To see what's happening, check out the events.

- sample (truncated) output of `kubectl get events -n devteam`:
```console
LAST SEEN   TYPE      REASON              OBJECT                        MESSAGE
72s         Normal    Scheduled           pod/nginx-6ffdc47948-kpl2j    Successfully assigned devteam/nginx-6ffdc47948-kpl2j to gke-playground-preempt-pool-feb1ce15-cnt7
...
...
70s         Normal    Created             pod/nginx-6ffdc47948-l4lpz    Created container nginx
70s         Normal    Started             pod/nginx-6ffdc47948-l4lpz    Started container nginx
73s         Normal    SuccessfulCreate    replicaset/nginx-6ffdc47948   Created pod: nginx-6ffdc47948-l4lpz
72s         Normal    SuccessfulCreate    replicaset/nginx-6ffdc47948   Created pod: nginx-6ffdc47948-kpl2j
17s         Warning   FailedCreate        replicaset/nginx-6ffdc47948   Error creating: pods "nginx-6ffdc47948-dj6th" is forbidden: exceeded quota: cpu-mem-quota, requested: limits.cpu=500m,requests.cpu=200m, used: limits.cpu=1,requests.cpu=400m, limited: limits.cpu=1,requests.cpu=500m
17s         Warning   FailedCreate        replicaset/nginx-6ffdc47948   Error creating: pods "nginx-6ffdc47948-s2h7b" is forbidden: exceeded quota: cpu-mem-quota, requested: limits.cpu=500m,requests.cpu=200m, used: limits.cpu=1,requests.cpu=400m, limited: limits.cpu=1,requests.cpu=500m
...
...
16s         Warning   FailedCreate        replicaset/nginx-6ffdc47948   Error creating: pods "nginx-6ffdc47948-n8h87" is forbidden: exceeded quota: cpu-mem-quota, requested: limits.cpu=500m,requests.cpu=200m, used: limits.cpu=1,requests.cpu=400m, limited: limits.cpu=1,requests.cpu=500m
7s          Warning   FailedCreate        replicaset/nginx-6ffdc47948   (combined from similar events): Error creating: pods "nginx-6ffdc47948-8f8cm" is forbidden: exceeded quota: cpu-mem-quota, requested: limits.cpu=500m,requests.cpu=200m, used: limits.cpu=1,requests.cpu=400m, limited: limits.cpu=1,requests.cpu=500m
73s         Normal    ScalingReplicaSet   deployment/nginx              Scaled up replica set nginx-6ffdc47948 to 2
17s         Normal    ScalingReplicaSet   deployment/nginx              Scaled up replica set nginx-6ffdc47948 to 3 from 2
```

Note that if you were to deploy into another namespace (i.e. default) instead, you can scale up (provided your node has sufficient resources).
