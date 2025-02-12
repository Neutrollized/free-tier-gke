# Cilium Clusterwide Network Policy (CCNP)

Kubernetes NetworkPolicy is namespace-scoped, and what CiliumClusterwideNetworkPolicy offers is a cluster-scoped policy for enforcing cluster-wide security policies.

Please set documentation page for the latest [requirements](https://cloud.google.com/kubernetes-engine/docs/how-to/configure-cilium-network-policy#req) and [limitations](https://cloud.google.com/kubernetes-engine/docs/how-to/configure-cilium-network-policy#limitations)

[Starwars demo app](../starwars-demo/http-sw-app.yaml)

You'll notice that it's very similar to the `CiliumNetorkPolicy`, and it is.  The only difference is these rules are **cluster-wide** and hence the differentiation in the name.
