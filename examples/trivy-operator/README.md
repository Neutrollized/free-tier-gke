# [Trivy Operator](https://github.com/aquasecurity/trivy-operator) 
Trivy Operator let's you continuously scan your Kubernetes (GKE) cluster for any security-related issues.  It's a great tool for any environments and industries where compliance is critical (or maybe you're just really security-conscious).

## Install
- install via helm:
```console
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update

helm search repo aqua/trivy-operator -l

helm install trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace \
  --version 0.22.0 \
  --set="excludeNamespaces=gke-managed-system\,kube-system"
```

**NOTE:** you need to escape the comma for the lists if you are setting options in command line.  


## Reports
There are a variety of reports that the Trivy Operator can produce, including some of my favorites:
- [RbacAssessmentReport](https://aquasecurity.github.io/trivy-operator/v0.20.0/docs/crds/rbacassessment-report/)
- [ClusterComplianceReport](https://aquasecurity.github.io/trivy-operator/v0.20.0/docs/crds/clustercompliance-report/)
- [ClusterVulnerabilityReport](https://aquasecurity.github.io/trivy-operator/v0.20.0/docs/crds/clustervulnerability-report/)
- and much more!


### NGINX Example
Apply both NGINX deployment manifests.  Once they are deployed, list the `vulnerabilityreport` and `configauditreport` resources (don't forget the `-o wide` flag). Despite both being just a simple NGINX web server, the image type (Debian base vs Alpine base) as well as the config and security context settings make a huge difference. 

#### Reports
- [VulnerabilityReport](https://aquasecurity.github.io/trivy-operator/v0.20.0/docs/vulnerability-scanning/trivy/) (`kubectl get vulnerabilityreport --all-namespaces -o wide`):
```
NAMESPACE      NAME                                                  REPOSITORY                    TAG                SCANNER   AGE     CRITICAL   HIGH   MEDIUM   LOW   UNKNOWN
default        replicaset-nginx-6bf45ff-nginx                        library/nginx                 latest             Trivy     15m     2          23     45       91    1
mynginx        replicaset-nginx-unpriv-58b44548b6-nginx              nginxinc/nginx-unprivileged   1.25-alpine-slim   Trivy     39s     0          0      0        0     0
```

- [ConfigAuditReport](https://aquasecurity.github.io/trivy-operator/v0.20.0/docs/crds/configaudit-report/) (`kubectl get configauditreport --all-namespaces -o wide`):
```
NAMESPACE      NAME                                   SCANNER   AGE     CRITICAL   HIGH   MEDIUM   LOW
default        replicaset-nginx-6bf45ff               Trivy     16m     0          3      8        13
default        service-nginx-svc                      Trivy     5m44s   0          0      0        2
mynginx        replicaset-nginx-unpriv-58b44548b6     Trivy     11s     0          1      5        2
mynginx        service-nginx-unpriv-svc               Trivy     5m31s   0          0      0        2
```
