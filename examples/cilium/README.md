# Cilium

## Installation 
Steps to install can be found [here](https://docs.cilium.io/en/latest/gettingstarted/k8s-install-default/), but basically boils down to:
```console
cilium install
cilium hubble enable --ui
```

The latter command installs [Hubble](https://docs.cilium.io/en/latest/gettingstarted/hubble_intro/), which is their observability plugin (optional, but recommended).

With Cilium deployed, you have now unlocked a new resource called `CiliumNetworkPolicy` (`cnp`).


## Star Wars demo
My deployment is a modified version of [Cilium's Star Wars demo](https://github.com/cilium/star-wars-demo)

### NetworkPolicy vs. CiliumNetworkPolicy
Below are the [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) equivalents of [`starwars-demo/sw_l3_l4_cnp.yaml`](./starwars-demo/sw_l3_l4_cnp.yaml) and [`starwars-demo/sw_deny_cnp.yaml`](./starwars-demo/sw_deny_cnp.yaml) respectively, and as you can see, they differ very little in structure so knowledge in defining policies in either format is transferrable to the other.  And while both network policy types will be honored, it is strongly recommended that you stick to one kind of policy rather than to mix and match.

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


## Boutique demo
The boutique demo comes from [GCP's microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo), and assuming you have open-source Cilium installed, you can apply the Cilium Network Policies (CNPs):

```console
kubectl apply -f ./boutique-demo/
```

On the surface, the boutique seems to be working (and it is), but actually the **adservice** is being blocked by the [Deny All](./boutique-demo/deny_all_cnp.yaml) policy.  If you installed Hubble, you will be able to see *DROPPED* traffic to/from the **adservice**.  To fix this, run:

```console
kubectl apply -f ./boutique-demo/extra/
```

Now, you should notice that there are some "sale" ads on the Online Boutique site!
