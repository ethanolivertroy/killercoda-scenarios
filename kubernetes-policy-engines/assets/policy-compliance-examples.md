# Kubernetes Policy Compliance Examples

This document provides examples of compliant and non-compliant Kubernetes resources for the policies implemented in this scenario. These examples can be used as part of your FedRAMP System Security Plan (SSP) to demonstrate how your policies enforce security controls.

## Required Labels Policy (CM-8)

### Non-Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-labels-pod
  # Missing required labels
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

### Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-labels-pod
  labels:
    app.kubernetes.io/name: secure-app  # Required label
    security-classification: internal    # Required label
    owner: security-team                 # Required label
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

## Privileged Containers Policy (AC-6)

### Non-Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-privileged-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    securityContext:
      privileged: true  # Privileged mode is not allowed
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

### Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-privileged-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    securityContext:
      privileged: false  # Explicitly disabled (or omitted)
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

## Allowed Repositories Policy (CM-7)

### Non-Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-repo-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/nginx:latest  # Not from allowed repository
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

### Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-repo-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest  # From allowed repository
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

## Resource Limits Policy (SC-6)

### Non-Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-resources-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    # Missing resource limits entirely
```

### Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-resources-pod
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
        cpu: "100m"  # CPU limit specified
        memory: "128Mi"  # Memory limit specified
      requests:
        cpu: "50m"
        memory: "64Mi"
```

## Host Namespaces Policy (SC-7)

### Non-Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-namespace-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  hostNetwork: true  # Not allowed to use host network
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

### Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-namespace-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  hostNetwork: false  # Explicitly disabled (or omitted)
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

## Linux Capabilities Policy (AC-6)

### Non-Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-capabilities-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    securityContext:
      capabilities:
        add: ["SYS_ADMIN"]  # Dangerous capability not allowed
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

### Compliant Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-capabilities-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    securityContext:
      capabilities:
        drop: ["ALL"]  # Drop all capabilities and add only what's needed
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

## Full Compliance Example

Below is an example of a pod that is compliant with all implemented policies:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fully-compliant-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  # Host namespaces explicitly disabled
  hostNetwork: false
  hostIPC: false
  hostPID: false
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    securityContext:
      privileged: false
      capabilities:
        drop: ["ALL"]
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
      requests:
        cpu: "50m"
        memory: "64Mi"
```

## Using These Examples

These examples should be included in your FedRAMP System Security Plan (SSP) to demonstrate:

1. The specific security controls enforced by your Kubernetes policies
2. How these policies work in practice with clear examples
3. What constitutes compliant and non-compliant configurations
4. How policies map to specific FedRAMP controls

When a security assessor reviews your environment, they can use these examples to validate that your policies are properly implemented and enforced.