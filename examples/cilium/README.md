# Cilium
Deployment manifests used here are taken from [Cilium's GitHub Repo](https://github.com/cilium/cilium/tree/master/examples/minikube) and thorough walkthrough of the example can be found [here](https://docs.cilium.io/en/latest/gettingstarted/http/)

With Cilium deployed, you have now unlocked a new resource called `CiliumNetworkPolicy` (`cnp`).

## NetworkPolicy vs. CiliumNetworkPolicy
Below are the [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) equivalents of [`sw_l3_l4_policy.yaml`](./sw_l3_l4_policy.yaml) and [`sw_deny_policy.yaml`](./sw_deny_policy.yaml) respectively, and as you can see, they differ very little in structure so knowledge in defining policies in either format is transferrable to the other.  And while both network policy types will be honored, it is strongly recommended that you stick to one kind of policy rather than to mix and match.

```
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-allow-empire
spec:
  podSelector:
    matchLabels:
      org: empire
      class: deathstar
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          org: empire
    ports:
    - port: 80
      protocol: TCP
```

```
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-deny-all
  namespace: default
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Ingress
  - Egress
```
