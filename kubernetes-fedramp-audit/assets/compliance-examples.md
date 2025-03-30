# Kubernetes FedRAMP Compliance Examples

This guide provides side-by-side comparisons between non-compliant and FedRAMP-compliant Kubernetes resource configurations.

## RBAC Examples

### Non-Compliant: Overly Permissive Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: non-compliant-role
  namespace: default
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

**Issues:**
- Wildcard permissions for all API groups
- Wildcard permissions for all resources
- Wildcard permissions for all verbs
- Violates NIST 800-53 AC-6 (Least Privilege)
- Violates CIS Kubernetes Benchmark 5.1.1

### Compliant: Least Privilege Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: compliant-role
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
  resourceNames: ["frontend", "backend"]
```

**Benefits:**
- Specific API groups instead of wildcards
- Specific resources instead of wildcards
- Limited verbs (read-only)
- Resource name restrictions where applicable
- Adheres to NIST 800-53 AC-6 (Least Privilege)
- Compliant with CIS Kubernetes Benchmark 5.1.1

---

## Pod Security Examples

### Non-Compliant: Privileged Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-pod
  namespace: default
spec:
  hostNetwork: true
  hostPID: true
  hostIPC: true
  containers:
  - name: non-compliant-container
    image: nginx:latest
    securityContext:
      privileged: true
      allowPrivilegeEscalation: true
      capabilities:
        add: ["ALL"]
      runAsUser: 0
    volumeMounts:
    - name: host-volume
      mountPath: /host
  volumes:
  - name: host-volume
    hostPath:
      path: /
      type: Directory
```

**Issues:**
- Uses host namespaces (hostNetwork, hostPID, hostIPC)
- Runs as privileged container
- Allows privilege escalation
- Adds ALL capabilities
- Runs as root user (UID 0)
- Mounts host root filesystem
- Violates NIST 800-53 SC-7, CM-7, AC-6
- Violates CIS Kubernetes Benchmark 4.2.1, 4.2.2, 4.2.3, 4.2.6, 4.2.7, 4.2.8

### Compliant: Secure Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: default
spec:
  containers:
  - name: compliant-container
    image: nginx:latest
    securityContext:
      privileged: false
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
      runAsUser: 1000
      runAsGroup: 1000
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      seccompProfile:
        type: RuntimeDefault
    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
```

**Benefits:**
- Doesn't use host namespaces
- Runs as non-privileged container
- Prevents privilege escalation
- Drops ALL capabilities
- Runs as non-root user with specific UIDs
- Uses read-only root filesystem
- Specifies Seccomp profile
- Sets resource limits
- Adheres to NIST 800-53 SC-7, CM-7, AC-6
- Compliant with CIS Kubernetes Benchmark 4.2.1 through 4.2.8

---

## Network Policy Examples

### Non-Compliant: No Network Policy

```yaml
# No network policy means all pods can communicate with each other,
# violating the principle of least privilege and FedRAMP requirements
# for information flow control and boundary protection
```

**Issues:**
- Allows unrestricted pod-to-pod communication
- No network segmentation
- No protection from lateral movement
- Violates NIST 800-53 SC-7 (Boundary Protection)
- Violates NIST 800-53 AC-4 (Information Flow Enforcement)

### Compliant: Restrictive Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: compliant-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
      namespaceSelector:
        matchLabels:
          environment: production
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
      namespaceSelector:
        matchLabels:
          environment: production
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

**Benefits:**
- Explicit ingress and egress rules
- Specific pod and namespace selectors
- Controlled port access
- DNS access for service discovery
- Implements "deny by default, allow by exception"
- Adheres to NIST 800-53 SC-7 (Boundary Protection)
- Adheres to NIST 800-53 AC-4 (Information Flow Enforcement)

---

## Secret Management Examples

### Non-Compliant: Plain Text Secrets

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-secrets-pod
  namespace: default
spec:
  containers:
  - name: app
    image: myapp:1.0.0
    env:
    - name: DB_PASSWORD
      value: "SuperSecretPassword123!"
    - name: API_KEY
      value: "sk_live_abcdefghijklmnopqrstuvwxyz12345"
```

**Issues:**
- Hardcoded secrets in plain text
- Exposed in pod specs and logs
- Visible to anyone with pod read access
- Violates NIST 800-53 IA-5 (Authenticator Management)
- Violates NIST 800-53 SC-12 (Cryptographic Key Management)

### Compliant: Kubernetes Secrets with Volume Mounts

```yaml
# First create the secret
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: default
type: Opaque
data:
  db-password: U3VwZXJTZWNyZXRQYXNzd29yZDEyMyE=  # base64 encoded
  api-key: c2tfbGl2ZV9hYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ejEyMzQ1  # base64 encoded

# Then reference it in the pod
apiVersion: v1
kind: Pod
metadata:
  name: compliant-secrets-pod
  namespace: default
spec:
  containers:
  - name: app
    image: myapp:1.0.0
    volumeMounts:
    - name: secrets-store
      mountPath: /mnt/secrets
      readOnly: true
  volumes:
  - name: secrets-store
    secret:
      secretName: app-secrets
      defaultMode: 0400  # Read-only for owner
```

**Benefits:**
- Secrets stored as Kubernetes resources
- Not visible in pod specs or logs
- Mounted as files, not environment variables
- Read-only access
- Restricted file permissions
- Adheres to NIST 800-53 IA-5 (Authenticator Management)
- Adheres to NIST 800-53 SC-12 (Cryptographic Key Management)

**Note:** For even better FedRAMP compliance, consider using an external secrets management solution like HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault with proper integration.

---

## Resource Limit Examples

### Non-Compliant: No Resource Limits

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-resources-pod
  namespace: default
spec:
  containers:
  - name: unlimited-container
    image: nginx:latest
    # No resource limits or requests specified
```

**Issues:**
- No CPU limits allows container to consume all available CPU
- No memory limits allows container to consume all available memory
- Could cause resource starvation and denial of service
- Violates NIST 800-53 SC-6 (Resource Availability)
- Violates CIS Kubernetes Benchmark 4.2.9

### Compliant: Resource Limits and Requests

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-resources-pod
  namespace: default
spec:
  containers:
  - name: limited-container
    image: nginx:latest
    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
```

**Benefits:**
- Explicit CPU and memory limits
- CPU and memory requests for scheduling
- Prevents resource starvation
- Ensures predictable performance
- Adheres to NIST 800-53 SC-6 (Resource Availability)
- Compliant with CIS Kubernetes Benchmark 4.2.9

---

## Additional FedRAMP Compliance Resources

For more examples and guidance, refer to:
- NIST 800-53 Rev. 5 security controls
- CIS Kubernetes Benchmark v1.6.1
- FedRAMP Security Controls Baseline
- Kubernetes Pod Security Standards