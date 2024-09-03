# Kyverno Policies

In this folder are a few Kyverno [sample policies](https://kyverno.io/policies/?policytypes=Best%2520Practices) (with a few minor edits) from the recommended best practices.  

I have also include a modified version of [Cilium's Starwars app](https://github.com/cilium/star-wars-demo) as an example.  There are 2 versions, one is compliant with 5 Kyverno policies I've include, and the other is not.

## Demo
Apply the 5 policies first, then try to deploy the demo app (`kubectl apply -f starwars-app.yaml`).  It contains a few components including a service of type `NodePort`, which should be disallowed (with the policy being *enforced*).  As a result, all but the service will be deployed and you should get an explicit error indicating what was blocked and why.

Wait about 15-20 seconds and list the policy reports (see section below) and it should indicate various failures with some of the elements in the deployment (but allowed to go through because they are in *audit* mode).  You can also see the details of each report to see the policy which it violated.

As mentioned, I've also included a version of the deployment YAMLs which meet all the policy rules, which you can apply to see (**NOTE:** you will have to delete the `xwing` and `tiefighter` pods manualy first).


## Kyverno Policy Report
There will be a policy report generate for each namespace for the workloads that are running in it.  To get a list, run `kubectl get polr -n [NAMESPACE]`

- example output:
```
NAME                                   KIND         NAME                         PASS   FAIL   WARN   ERROR   SKIP   AGE
014a69b5-1baf-4f8a-a2bc-a6a9edf92c75   ReplicaSet   deathstar-6fc7947d89         6      2      0      0       0      114s
34f10adb-3c1e-404d-8e70-13f43fde31bd   Service      kubernetes                   1      0      0      0       0      135m
3d87ce42-5b91-4b38-8dfa-899bfc85a656   Pod          xwing                        8      0      0      0       0      5m7s
485de1b8-79f0-45f7-9989-d64b35b0866d   ReplicaSet   deathstar-65c7c5f9b9         7      1      0      0       0      4m47s
be71074b-7a7c-4a73-8428-3a107cfa810b   Pod          tiefighter                   7      1      0      0       0      4m28s
cafa4a23-049a-4095-b411-605a308a4384   Pod          deathstar-6fc7947d89-sdb7w   6      2      0      0       0      2m12s
eff1f6fc-0d29-4b99-9f71-eccdcc7d5e53   Deployment   deathstar                    6      3      0      0       0      5m7s
ff2b137b-2bb0-470f-9057-8b8a79d5fa58   Pod          deathstar-6fc7947d89-tbwts   6      2      0      0       0      2m14s
```


### Policy Report details
To see the details of a report, run: `kubectl describe polr [POLICY_REPORT_NAME] -n [NAMESPACE]`

- sample (shortened) output: 
```
Name:         eff1f6fc-0d29-4b99-9f71-eccdcc7d5e53
Namespace:    default
Labels:       app.kubernetes.io/managed-by=kyverno
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport
Metadata:
  Creation Timestamp:  2024-08-26T20:19:16Z
  Generation:          4
  Owner References:
    API Version:     apps/v1
    Kind:            Deployment
    Name:            deathstar
    UID:             eff1f6fc-0d29-4b99-9f71-eccdcc7d5e53
  Resource Version:  175914
  UID:               ba154d78-c7be-4616-89ba-fed4a85875f6
Results:
...
...
...
  Category:   Best Practices
  Message:    validation rule 'autogen-validate-image-tag' passed.
  Policy:     disallow-latest-tag
  Result:     pass
  Rule:       autogen-validate-image-tag
  Scored:     true
  Severity:   medium
  Source:     kyverno
  Timestamp:
    Nanos:    0
    Seconds:  1724703739
  Category:   Best Practices
  Message:    validation error: The label `app.kubernetes.io/name` is required. rule autogen-check-for-labels failed at path /spec/templa
---
te/metadata/labels/app.kubernetes.io/name/
  Policy:     require-labels
  Result:     fail
  Rule:       autogen-check-for-labels
  Scored:     true
  Severity:   medium
  Source:     kyverno
  Timestamp:
    Nanos:    0
    Seconds:  1724703739
Scope:
  API Version:  apps/v1
  Kind:         Deployment
  Name:         deathstar
  Namespace:    default
  UID:          eff1f6fc-0d29-4b99-9f71-eccdcc7d5e53
Summary:
  Error:  0
  Fail:   1
  Pass:   6
  Skip:   0
  Warn:   0
Events:   <none>
```
