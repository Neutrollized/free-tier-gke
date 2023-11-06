# README
This example requires the GKE Dataplane V2 feature be enabled.

## Setup
```console
helm repo add cilium https://helm.cilium.io
helm repo update
helm install tetragon cilium/tetragon -n kube-system
```

- upgrade:
```console
helm upgrade tetragon cilium/tetragon -n kube-system
```

### Configuration
If you want to update Tetragon's config, you can do so by editing ConfigMap:
```console
kubectl edit configmap -n kube-system tetragon-config
```
You can, for example, set `enable-process-cred` to `true`, will enable visibility to capability changes/privileged execution (i.e. `CAP_SYS_ADMIN`)

After you've made your changes, you will need to restart the Tetragon daemonset with:
```console
kubectl rollout restart -n kube-system ds/tetragon
```

### Tetragon CLI
I suggest making an alias if you don't already have the Tetragon CLI installed on your system, as you will be calling `tetra` from one of the tetragon containers (if you want to use `tetra` that's on your local system, replace `gketetra`):

```console
alias gketetra='kubectl exec -it -n kube-system ds/tetragon -c tetragon -- tetra '
alias tetralogs='kubectl logs -n kube-system -l app.kubernetes.io/name=tetragon -c export-stdout -f | gketetra getevents -o compact '
```
(the second alias will be more relevant later on)


```console
gketetra status

gketetra version
```

- output:
```
Health Status: running

CLI version: v1.0.0
```

#### Sample usage
```console
tetralogs --namespace default --pods myapp
```


## Tracing Policy examples

### fd_install
The kprobe, `fd_install` is called when a new file descriptor needs to be created.  The following policy prevents a few file descriptor from being created, provided that file is */tmp/tetragon*.  It will trigger a SIGKILL to kill off the pocess trying to create the file:
```console
kubectl apply -f ./fd-install.yaml
```

- notice how writing to */tmp/bar* is okay, but */tmp/tetragon* will trigger an SIGKILL on the process (in my case, the kubectl exec -it /bin/bash shell)
```
bash-4.3# echo 'foo' > /tmp/bar
bash-4.3# echo 'foo' > /tmp/tetragon
command terminated with exit code 137
```


### tcp_connect, tcp_sendmsg, and tcp_close
These kprobes are used for creating a tcp connection, sending data and closing the connection respectively.  Applying this will add extra entries in the `tetra getevents -o compact` output (or in our case, `gketetra`).

```console
kubectl apply -f ./tcp-connection.yaml
```

- below is a sample output of `kubectl exec -it tiefighter -n galaxy -- curl -XPOST deathstar.galaxy.svc.cluster.local/v1/request-landing` with the [Starwars demo app](../cilium/starwars-demo/http-sw-app.yaml):
```
🚀 process galaxy/tiefighter /usr/bin/curl -s -XPOST deathstar.galaxy.svc.cluster.local/v1/request-landing
🔌 connect galaxy/tiefighter /usr/bin/curl tcp 10.0.0.7:43724 -> 10.1.11.240:80
📤 sendmsg galaxy/tiefighter /usr/bin/curl tcp 10.0.0.7:43724 -> 10.1.11.240:80 bytes 117
🧹 close   galaxy/tiefighter /usr/bin/curl tcp 10.0.0.7:43724 -> 10.1.11.240:80
💥 exit    galaxy/tiefighter /usr/bin/curl -s -XPOST deathstar.galaxy.svc.cluster.local/v1/request-landing 0
```

### Block Internet egress
The following policy blocks any egress traffic that is outside of the CIDRs specified.  In my case it was *127.0.0.1* (localhost), *10.0.0.0/18* (pod CIDR, `cluster_ipv4_cidr_block` Terraform variable value) and *10.1.0.0/20* (services CIDR, `services_ipv4_cidr_block` Terraform variable value):
```console
kubectl apply -f ./block-internet-egress.yaml
```

You will also notice that this is a `TracingPolicyNamespaced`, which works the same way as a `TracingPolicy`, except it is namespace-scoped (as you can probably already guess)

- you get the following if you try to access something outside the specified CIDR ranges from within a pod:
```
# curl www.google.com
Killed
```
