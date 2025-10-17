# Tetragon

I wrote a couple of Medium articles on Tetragon [here](https://medium.com/@glen.yu/getting-started-with-tetragon-on-gke-2c11549720b0) and [here](https://medium.com/google-cloud/google-cloud-logging-and-cloud-monitoring-example-with-tetragon-5eb2012066d4)

> [!NOTE]
> Tetragon can work standalone and does NOT require Cilium (or GKE Dataplane V2) to be installed.


## Setup
```
helm repo add cilium https://helm.cilium.io
helm repo update

helm search repo cilium/tetragon -l

helm install tetragon cilium/tetragon \
  --namespace kube-system \
  --version 1.4.1
```

> [!NOTE]
> I also have an [ArgoCD Helm deployment example](../argocd/README.md#creating-and-syncing-application)


- upgrade:
```
helm upgrade tetragon cilium/tetragon -n kube-system
```

### Configuration
If you want to update Tetragon's config, you can do so by editing ConfigMap:
```
kubectl edit configmap -n kube-system tetragon-config
```
You can, for example, set `enable-process-cred` to `true`, will enable visibility to capability changes/privileged execution (i.e. `CAP_SYS_ADMIN`)

After you've made your changes, you will need to restart the Tetragon daemonset with:
```
kubectl rollout restart -n kube-system ds/tetragon
```

> [!TIP]
> I highly recommend making an alias if you don't already have the [Tetragon CLI](https://tetragon.io/docs/installation/tetra-cli/) installed on your system, as you will be calling `tetra` from one of the tetragon containers (if you want to use `tetra` that's on your local system, replace `ktetra`):
>
> ```sh
> alias ktetra='kubectl exec -it -n kube-system ds/tetragon -c tetragon -- tetra '
> alias tetralogs='kubectl logs -n kube-system -l app.kubernetes.io/name=tetragon -c export-stdout -f | ktetra getevents -o compact '
> ```
> (the second alias will be more relevant later on)
>
> ```sh
> ktetra status
> 
> ktetra version
> ```
> 
> - output:
> ```console
> Health Status: running
> 
> CLI version: v1.4.1
> ```
>
> - sample useage of `tetralogs` alias:
> ```sh
> tetralogs --namespace default --pods myapp
> ```


## Tracing Policy examples

### [fd_install](https://elixir.bootlin.com/linux/v6.6.7/source/fs/file.c#L602) (Basic)
The kernel function, `fd_install` is called when a new file descriptor needs to be created.  The following policy prevents a few file descriptor from being created (or opened if it already exists), provided that file is */tmp/tetragon*.  It will trigger a SIGKILL to kill off the pocess trying to create the file:
```console
kubectl apply -f ./block-fd-install.yaml
```

- notice how writing to */tmp/bar* is okay, but */tmp/tetragon* will trigger an SIGKILL on the process (in my case, the kubectl exec -it /bin/bash shell)
```sh
bash-4.3# echo 'foo' > /tmp/bar
bash-4.3# echo 'foo' > /tmp/tetragon
command terminated with exit code 137
```

### fd_install (Intermediate)
For a little more advanced example, deploy my `nginx-deployment.yaml` example (one folder up) and then apply the `block-nginx-write-index.yaml`:
```
kubectl apply -f ../nginx-deployment.yaml

kubectl apply -f ./block-nginx-write-index.yaml
```

The following block ignores (`NotIn`) the container's init PID (in our case, NGINX).  Because this policy blocks the `fd_install` kernel function, we do not want to preven NGINX from reading the index.html.  This sets the stage to apply the policy only to other PIDs (i.e. from `kubectl exec`).  This is a fairly common pattern, so learn to recognize it:
```yaml
    - matchPIDs:
      - operator: "NotIn"
        followForks: false
        isNamespacePID: true
        values:
        - 0
        - 1
```

- matches argument to be anything in the following path list:
```yaml
      matchArgs:
      - index: 1
        operator: "Prefix"
        values:
        - "/usr/share/nginx/html/"
```

- finally, allowlist the `cat` command (so you can open the file provided it's with `cat`, but `sed`, `vi` or anything else not in this list will get sent a SIGKILL):
```yaml
      matchBinaries:
      - operator: "NotIn"
        values:
         - "/usr/bin/cat"
```


### [tcp_connect](https://elixir.bootlin.com/linux/v6.6.7/source/net/ipv4/tcp_output.c#L3946), [tcp_sendmsg](https://elixir.bootlin.com/linux/v6.6.7/source/net/ipv4/tcp.c#L1335), and [tcp_close](https://elixir.bootlin.com/linux/v6.6.7/source/net/ipv4/tcp.c#L2918)
These kprobes are used for creating a tcp connection, sending data and closing the connection respectively.  Applying this will add extra entries in the `tetra getevents -o compact` output (or in our case, `ktetra`).

```
kubectl apply -f ./log-tcp-connection.yaml
```

- below is a sample output of `kubectl exec -it tiefighter -n galaxy -- curl -XPOST deathstar.galaxy.svc.cluster.local/v1/request-landing` with the [Starwars demo app](../cilium/starwars-demo/http-sw-app.yaml):
```console
🚀 process galaxy/tiefighter /usr/bin/curl -s -XPOST deathstar.galaxy.svc.cluster.local/v1/request-landing
🔌 connect galaxy/tiefighter /usr/bin/curl tcp 10.0.0.7:43724 -> 10.1.11.240:80
📤 sendmsg galaxy/tiefighter /usr/bin/curl tcp 10.0.0.7:43724 -> 10.1.11.240:80 bytes 117
🧹 close   galaxy/tiefighter /usr/bin/curl tcp 10.0.0.7:43724 -> 10.1.11.240:80
💥 exit    galaxy/tiefighter /usr/bin/curl -s -XPOST deathstar.galaxy.svc.cluster.local/v1/request-landing 0
```

### Block Internet egress
The following policy blocks any egress traffic that is outside of the CIDRs specified.  In my case it was *127.0.0.1* (localhost), *10.0.0.0/18* (pod CIDR, `cluster_ipv4_cidr_block` Terraform variable value) and *10.1.0.0/20* (services CIDR, `services_ipv4_cidr_block` Terraform variable value):
```
kubectl apply -f ./block-internet-egress.yaml
```

You will also notice that this is a `TracingPolicyNamespaced`, which works the same way as a `TracingPolicy`, except it is namespace-scoped (as you can probably already guess)

- you get the following if you try to access something outside the specified CIDR ranges from within a pod:
```sh
curl www.google.com
Killed
```


## Additional Notes
Check out the [monitoring alerts](./monitoring-alerts/) folder to see how to setup [Cloud Monitoring](https://cloud.google.com/monitoring) alert policies

### Using the [Override action](https://tetragon.io/docs/concepts/tracing-policy/selectors/#override-action)
At the time of writing, GKE nodes do not have `CONFIG_BPF_KPROBE_OVERRIDE` set, which is a requirement in order to leverage this action.  I've created a [feature request](https://issuetracker.google.com/issues/366752999) with Google's Issue Tracker and would appreciate any and all upvotes to help expedite this feature.

### Kernel Function References
- [fd_install](https://elixir.bootlin.com/linux/v6.6.7/source/fs/file.c#L602)
- [tcp_connect](https://elixir.bootlin.com/linux/v6.6.7/source/net/ipv4/tcp_output.c#L3946)
- [tcp_sendmsg](https://elixir.bootlin.com/linux/v6.6.7/source/net/ipv4/tcp.c#L1335)
- [tcp_close](https://elixir.bootlin.com/linux/v6.6.7/source/net/ipv4/tcp.c#L2918)
- [security_file_permission](https://elixir.bootlin.com/linux/v6.6.7/source/security/security.c#L2581)
- [security_bprm_creds_from_file](https://elixir.bootlin.com/linux/v6.6.7/source/security/security.c#L1082)
