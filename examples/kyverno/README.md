# Kyverno
[Kyverno](https://kyverno.io/docs/introduction/) is a policy engine designed for k8s and is also an incubating CNCF project.

I wrote a Medium article on Kyverno vs. OPA Gatekeeper [here](https://medium.com/@glen.yu/why-i-prefer-kyverno-over-gatekeeper-for-native-kubernetes-policy-management-35a05bb94964)

## Install
- install via helm:
```console
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm search repo kyverno -l

helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

- optionally install Kyverno policies (full set of Kyverno policies which implement PSP):
```console
helm install kyverno-policies kyverno/kyverno-policies -n kyverno
```

## Policy Rules

### Exclusions
- namespace:
```
...
  exclude:
    any:
    - resources:
        namespaces:
        - kube-system
...
```
- **NOTE**: exclusion of the `kube-system` namespace is aready implied so no need to explicitly state (unless you want to)


## Example
Run `kubectl apply -f ./require-ns-label.yaml` to apply the policy that namespaces require a label called `env`.  If you apply the namespace manifest provided (`kubectl apply -f namespace.yaml`), it will result in an error, which you can fix by uncommenting out the last line which contains the required label.
