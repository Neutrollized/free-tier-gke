# Harbor

[Harbor](https://goharbor.io/) is an open-source (CNCF) registry project. Perfect if you need host your own local registry rather than use a service from a cloud provider.

This deployment uses [Task](https://taskfile.dev/) to manage much of the deployment steps. You don't have to use it, and can look through `Taskfile.yaml` to find the commands for each of the steps.

> [!IMPORTANT]
> Without a proper DNS/external URL, the Harbor portal login will not work, hence the final crucial step (`task update:ingress`)
> is important if you're installing this from a test/learning perspective and don't have an external URL.
