# GKE Dataplane V2 observability tools

I wrote a Medium article on Hubble [here](https://medium.com/@glen.yu/using-hubble-with-gke-dataplane-v2-acb73d1291c6)

This example requires the GKE Dataplane V2 observability feature be enabled. **Enabling this feature will provision an internal network load balancer**.

**UPDATE 2024-08-14**: GKE DPv2 observability has gone through some updates since. So I'm just going to link the relevant Google Cloud docs to get setup with the CLI and UI:

- [How to use Hubble CLI](https://cloud.google.com/kubernetes-engine/docs/how-to/configure-dpv2-observability#configure-cli-binary-distribution)

- [How to deploy the Hubble UI binary distribution](https://cloud.google.com/kubernetes-engine/docs/how-to/configure-dpv2-observability#how_to_deploy_the_hubble_ui_binary_distribution)


## Random info
There was a typo in the documentation for the `advanced_datapath_observability_config` setting so I made [PR#8813](https://github.com/GoogleCloudPlatform/magic-modules/pull/8813) to correct.
