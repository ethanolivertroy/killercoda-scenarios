# Implementing Policies for FedRAMP Controls with Kubernetes Native Admission

In this step, we will:
1. Learn about Kubernetes ValidatingAdmissionPolicies - a more lightweight alternative
2. Create admission policies for key FedRAMP controls
3. Apply policy bindings to enforce our security requirements

> **Note:** We're using Kubernetes native ValidatingAdmissionPolicy (beta feature) instead of OPA Gatekeeper for a more lightweight approach with fewer resource requirements.

## Understanding ValidatingAdmissionPolicy

ValidatingAdmissionPolicy is a Kubernetes feature that provides policy enforcement without requiring additional controllers or webhooks. It uses Common Expression Language (CEL) for validation rules.

Let's check if the feature is enabled in our cluster:

```
kubectl api-resources | grep validatingadmissionpolicy
```{{exec}}

If this returns resources, the feature is enabled. Let's verify our Kubernetes version:

```
kubectl version --short
```{{exec}}

## Creating ValidatingAdmissionPolicies

Now let's create policies for key FedRAMP controls using the ValidatingAdmissionPolicy resource. We'll implement the same security controls that traditional policy engines enforce, but using Kubernetes native capabilities.

Let's create our first policy for required security labels (maps to CM-8):

```
cat <<EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-security-labels
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["pods"]
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments", "statefulsets", "daemonsets"] 
  validations:
    - expression: "has(object.metadata.labels) && has(object.metadata.labels['app.kubernetes.io/name'])"
      message: "Label 'app.kubernetes.io/name' is required"
    - expression: "has(object.metadata.labels) && has(object.metadata.labels['security-classification'])"
      message: "Label 'security-classification' is required"
    - expression: "has(object.metadata.labels) && has(object.metadata.labels['owner'])"
      message: "Label 'owner' is required"
EOF
```{{exec}}

Now, let's create a policy to block privileged containers (maps to AC-6):

```
cat <<EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingAdmissionPolicy
metadata:
  name: block-privileged-containers
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["pods"]
  validations:
    - expression: "!has(object.spec.containers[0].securityContext) || !has(object.spec.containers[0].securityContext.privileged) || object.spec.containers[0].securityContext.privileged == false"
      message: "Privileged containers are not allowed"
EOF
```{{exec}}

Let's verify that our admission policies are created:

```
kubectl get validatingadmissionpolicies
```{{exec}}

## Creating Policy Bindings

For our policies to take effect, we need to create bindings that connect them to our cluster. Let's create bindings for our policies:

```
cat <<EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-security-labels-binding
spec:
  policyName: require-security-labels
  validationActions: ["Deny"]
---
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: block-privileged-containers-binding
spec:
  policyName: block-privileged-containers
  validationActions: ["Deny"]
EOF
```{{exec}}

Now let's create two more policies for allowed repositories and resource limits:

```
cat <<EOF | kubectl apply -f -
# Allowed Repositories (CM-7: Least Functionality)
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingAdmissionPolicy
metadata:
  name: allowed-image-repos
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["pods"]
  validations:
    - expression: "object.spec.containers.all(c, c.image.startsWith('gcr.io/my-fedramp-project/') || c.image.startsWith('registry.internal.fedramp.gov/') || c.image.startsWith('k8s.gcr.io/') || c.image.startsWith('docker.io/bitnami/'))"
      message: "Container images must come from an approved repository"
---
# Resource Limits (SC-6: Resource Availability)
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-resource-limits
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["pods"]
  validations:
    - expression: "object.spec.containers.all(c, has(c.resources) && has(c.resources.limits) && has(c.resources.limits.cpu) && has(c.resources.limits.memory))"
      message: "All containers must have CPU and memory limits defined"
EOF
```{{exec}}

And create bindings for these policies:

```
cat <<EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: allowed-image-repos-binding
spec:
  policyName: allowed-image-repos
  validationActions: ["Deny"]
---
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-resource-limits-binding
spec:
  policyName: require-resource-limits
  validationActions: ["Deny"]
EOF
```{{exec}}

## Testing Policy Enforcement

Let's test our policies by attempting to deploy a non-compliant pod:

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    securityContext:
      privileged: true
EOF
```{{exec}}

This should be blocked by our policies. Now let's create a compliant pod:

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
      requests:
        cpu: "50m"
        memory: "64Mi"
EOF
```{{exec}}

## Monitoring and Auditing

We can examine our policy enforcement by checking the validation admission policies:

```
kubectl get validatingadmissionpolicies -o wide
```{{exec}}

And verify the bindings:

```
kubectl get validatingadmissionpolicybindings
```{{exec}}

## Advantages of Using ValidatingAdmissionPolicy

This native Kubernetes approach provides several advantages:

1. **Lightweight**: No additional controllers or webhooks required
2. **Performance**: CEL expressions are evaluated in-process with lower overhead
3. **Resource Efficient**: Minimal resource consumption compared to external policy engines
4. **Native Integration**: Built directly into the Kubernetes API server

This completes our implementation of ValidatingAdmissionPolicy for key FedRAMP controls. In the next step, we'll explore a more Kubernetes-native policy approach with Kyverno.