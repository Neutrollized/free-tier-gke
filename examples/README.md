# Sample Kubernetes Deployments
I've included an example deployment of nginx with *LoadBalancer* (GCP ALB) service.  Please note that the deployment does provision an GCP load balancer so this will incur extra charges if you leave it running for too long.

To deploy: `kubectl apply -f nginx-deployment.yaml`

To delete: `kubectl delete -f nginx-deployment.yaml`

The pods should deploy fairly quickly, but the service might take a bit before you get the load balancer's public IP (you can do a `watch kubectl get service` if you're the impatient type)

## Horizontal Pod Autoscaling
The command line equivalent of the HPA manifest is:
```
kubectl autoscale deployment nginx --cpu-percent=10 --min=1 --max=5
```

- stress test your deployment with:
```sh
ab -n 100000 -c 5000 http://[LOADBALANCER_IP]/
```

> [!NOTE]
> I set the autoscale condition artificially low to get HPA to trigger easier.  In practice you probably want higher CPU utilization like 50-60%+


## Taskfile

I've started to incorporate Taskfile for some of my examples. This is optional, but if you have [Task](https://taskfile.dev/) installed, this is very much like Makefile, but for Kubernetes. If there's a `Taskfile.yaml` in the example directory, feel free to take a look at its contents for the various setup commands.

#### (There are also other examples in here if you want try them out as well)
