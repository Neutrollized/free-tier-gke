# GKE Dataplane V2 observability tools

I wrote a Medium article on Hubble [here](https://medium.com/@glen.yu/using-hubble-with-gke-dataplane-v2-acb73d1291c6)

This example requires the GKE Dataplane V2 observability feature be enabled. **Enabling this feature will provision an internal network load balancer**.

**UPDATE 2024-08-14**: GKE DPv2 observability has gone through some updates since. So I'm just going to link the relevant Google Cloud docs to get setup with the CLI and UI:

- [How to use Hubble CLI](https://cloud.google.com/kubernetes-engine/docs/how-to/configure-dpv2-observability#configure-cli-binary-distribution)

- [How to deploy the Hubble UI binary distribution](https://cloud.google.com/kubernetes-engine/docs/how-to/configure-dpv2-observability#how_to_deploy_the_hubble_ui_binary_distribution)


- the following are aliases I set up in my shell environment to make life easier:
```sh
alias gkehubble="kubectl exec -it -n gke-managed-dpv2-observability deployment/hubble-relay -c hubble-cli -- hubble "

alias gkehubbleobserve="kubectl exec -it -n gke-managed-dpv2-observability deployment/hubble-relay -c hubble-cli -- hubble observe --follow --not --namespace kube-system --not --namespace gke-managed-dpv2-observability --not --namespace gke-managed-system "

alias gkehubbleui="kubectl -n gke-managed-dpv2-observability port-forward service/hubble-ui 16100:80 --address='127.0.0.1'"
```

## Random info
There was a typo in the documentation for the `advanced_datapath_observability_config` setting so I made [PR#8813](https://github.com/GoogleCloudPlatform/magic-modules/pull/8813) to correct it.
