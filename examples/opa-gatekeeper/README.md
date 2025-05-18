# OPA Gatekeeper

```
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update

helm search repo gatekeeper -l

helm install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system \
  --create-namespace \
  --version 3.19.1
```

### Cleanup
```
helm delete gatekeeper -n gatekeeper-system
```


## How-to
You first need to define a `ContraintsTemplate` which is written in [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) and is used to define you policy.  Afterwards, you can create rules based on these policies.  Included in this directory is a couple of policies as well as rules that are built upon these policies.

Example policies include:
- policy for image tag names
- policy for enforcing namespace labels


### NOTE
- if the k8simagetag `ContraintsTemplate` violation was the following, then the latest tag is effectively hardcoded (compared the current one)
```yaml
...
...
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          endswith(container.image, ":latest")
          msg := sprintf("container <%v> uses an image tagged with latest <%v>", [container.name, container.image])
        }
```


## Testing
```
kubectl run nginx-test --image nginx:latest
```

Produces error:
```console
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [deny-latest-tags] container <nginx-test> uses an image tagged with latest <nginx:latest>
```
