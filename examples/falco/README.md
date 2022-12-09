# README
How to install & use [Falco](https://falco.org/), an eBPF-based cloud-native runtime security open sourced project.


## Prerequisites
You will need something beefier than an **e2-medium** node machine type.  I personally use an **n2d-standard-2**.

## Setup
Add the Helm chart:
```
helm repo add falcosecurity https://falcosecurity.github.io/charts
```


Install using Helm (set driver to `ebpf`):
```
helm install falco falcosecurity/falco \
  --set driver.kind=ebpf \
  --namespace falco \
  --create-namespace
```


## Adding Custom Rules
If you want to add custom rules, you can redeploy falco with helm and specify custom rules file:
```
helm upgrade falco falcosecurity/falco --set driver.kind=ebpf --namespace falco -f ./custom_falco_rules.yaml
```

## Testing
Spin up any pod and then exec into it.  It should get logged by Falco by one of its default rules (*priority: NOTICE*) as well as the custom rule (*priority: CRITICAL*) that was included in this repo (if you added it)

- sample Falco log output:
```
+ falco-5zh6f › falco
falco-5zh6f falco Fri Dec  9 02:48:25 2022: Falco version: 0.33.1 (x86_64)
falco-5zh6f falco Fri Dec  9 02:48:25 2022: Falco initialized with configuration file: /etc/falco/falco.yaml
falco-5zh6f falco Fri Dec  9 02:48:25 2022: Loading rules from file /etc/falco/falco_rules.yaml
falco-5zh6f falco Fri Dec  9 02:48:25 2022: Loading rules from file /etc/falco/falco_rules.local.yaml
falco-5zh6f falco Fri Dec  9 02:48:25 2022: Loading rules from file /etc/falco/rules.d/rules-shell.yaml
falco-5zh6f falco Rules match ignored syscall: warning (ignored-evttype):
...
...
falco-5zh6f falco 02:49:40.301467484: Notice User management binary command run outside of container (user=<NA> user_loginuid=-1 command=groupadd google-sudoers pid=131321 parent=google_guest_ag gparent=systemd ggparent=<NA> gggparent=<NA>) k8s.ns=<NA> k8s.pod=<NA> container=host
falco-5zh6f falco 02:50:12.120085823: Notice A shell was spawned in a container with an attached terminal (user=<NA> user_loginuid=-1 k8s.ns=default k8s.pod=nginx-deployment-5b567ff889-ttc64 container=5240d67d92bb shell=sh parent=runc cmdline=sh pid=131720 terminal=34816 container_id=5240d67d92bb image=docker.io/library/nginx)
falco-5zh6f falco 02:50:12.120170913: Critical Shell opened (user=<NA> container_id=5240d67d92bb container_name=nginx) k8s.ns=default k8s.pod=nginx-deployment-5b567ff889-ttc64 container=5240d67d92bb
falco-5zh6f falco 02:50:12.120180663: Critical Shell opened (user=<NA> container_id=5240d67d92bb container_name=nginx) k8s.ns=default k8s.pod=nginx-deployment-5b567ff889-ttc64 container=5240d67d92bb
...
...
```
