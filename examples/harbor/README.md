# Harbor

[Harbor](https://goharbor.io/) is an open-source (CNCF) registry project. Perfect if you need host your own local registry rather than use a service from a cloud provider.

This deployment uses [Task](https://taskfile.dev/) to manage much of the deployment steps. You don't have to use it, and can look through `Taskfile.yaml` to find the commands for each of the steps.

> [!IMPORTANT]
> Without a proper DNS/external URL, the Harbor portal login will not work, hence the final crucial step (`task update:ingress`)
> is important if you're installing this from a test/learning perspective and don't have an external URL.


## Example - Podman Desktop
After you have the Ingress IP, you will need to add it to Podman as you won't have any valid certificates. Follow the instructions for [adding insecure registries to Podman](https://podman-desktop.io/docs/containers/registries#setting-up-a-registry-with-an-insecure-certificate).

> [!NOTE]
> Replace with your actual Ingress IP, of course :)

- authenticate to Harbor registry:
```bash
podman login 123.45.67.89.nip.io --tls-verify=false
```

- build (set the platform appropriate to your env/setup) and tag image:
```bash
podman build --platform linux/arm64 -t hello-harbor:v1 .

podman tag hello-harbor:v1 123.45.67.89.nip.io/testproj/hello-harbor:v1
```

- push image to Harbor registry:
```bash
podman push 123.45.67.89.nip.io/testproj/hello-harbor:v1 --tls-verify=false
```

> [!NOTE]
> If you want to purge all the saved auths you made to your Harbor setup,
> you can find it in `~/.config/containers/auth.json`


## TODO
- Use Workload Identity Federation with GCP services such as GCS and/or Cloud SQL
