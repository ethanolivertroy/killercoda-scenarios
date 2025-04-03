# Service Mesh FedRAMP Compliance Examples

This document provides examples of compliant and non-compliant configurations for Linkerd service meshes in the context of FedRAMP requirements.

## mTLS Configuration Examples

### Non-Compliant: Missing Annotation for mTLS

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: insecure-apps
  # Missing linkerd.io/inject annotation
```

**Issues:**
- Workloads in namespace will not be part of the mesh
- No automatic mTLS for the workloads
- Violates SC-8 (Transmission Confidentiality and Integrity)
- Does not enforce strong authentication between services

### Compliant: Proper Mesh Inclusion for mTLS

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-apps
  annotations:
    linkerd.io/inject: enabled
```

**Benefits:**
- All workloads in namespace will be injected with Linkerd proxy
- Automatic mTLS for all service-to-service communication
- Ensures mutual authentication between services
- Complies with SC-8 (Transmission Confidentiality and Integrity)
- Complies with SC-13 (Cryptographic Protection)
- Complies with IA-3 (Device Identification and Authentication)

## Authorization Policy Examples

### Non-Compliant: No Authorization Policies

```yaml
# No ServerAuthorization policies defined
# This means all meshed services can communicate with each other
```

**Issues:**
- Violates AC-3 (Access Enforcement)
- Violates AC-6 (Least Privilege)
- Allows any meshed service to access any other service
- No fine-grained access control

### Compliant: Server Authorization Policies

```yaml
# Define a ServerAuthorization policy 
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  name: backend-server-auth
  namespace: secure-apps
spec:
  server:
    selector:
      matchLabels:
        app: backend
  client:
    # Only allow specific services to communicate with backend
    meshTLS:
      unauthenticated: false
      identities:
      - "*.secure-apps.serviceaccount.identity.linkerd.cluster.local"
    networks:
    - cidr: "10.0.0.0/8"
      except:
      - "10.1.1.0/24"
```

**Benefits:**
- Implements least privilege principle
- Only allows specific, well-defined services to communicate
- Denies unauthenticated requests
- Specifies authorized identities
- Network-level restriction with CIDR blocks
- Complies with AC-3 (Access Enforcement)
- Complies with AC-6 (Least Privilege)
- Complies with AC-4 (Information Flow Control)

## Authentication Examples

### Non-Compliant: Missing Identity Configuration

```yaml
# Improper identity configuration with short-lived certificates
# or missing trust anchors
apiVersion: helm.linkerd.io/v1alpha1
kind: IdentityConfiguration
spec:
  # Missing crtPEM and keyPEM
  crtExpiry: 24h  # Too short for proper operation
```

**Issues:**
- Identity service improperly configured
- Certificate expiration too short
- Missing trust anchors
- Violates SC-12 (Cryptographic Key Establishment and Management)
- Violates SC-17 (Public Key Infrastructure Certificates)
- Violates IA-5 (Authenticator Management)

### Compliant: Proper Identity Configuration

```yaml
# Proper identity configuration with secure parameters
apiVersion: helm.linkerd.io/v1alpha1
kind: IdentityConfiguration
spec:
  trustAnchorsPEM: |
    -----BEGIN CERTIFICATE-----
    ... Certificate data ...
    -----END CERTIFICATE-----
  keyPEM: |
    -----BEGIN PRIVATE KEY-----
    ... Key data ...
    -----END PRIVATE KEY-----
  crtPEM: |
    -----BEGIN CERTIFICATE-----
    ... Certificate data ...
    -----END CERTIFICATE-----
  crtExpiry: 8760h  # 1 year - properly sized for a production environment
```

**Benefits:**
- Properly configured identity service
- Secure certificate lifecycle
- Strong identity with mTLS
- Complies with SC-12 (Cryptographic Key Establishment and Management)
- Complies with SC-17 (Public Key Infrastructure Certificates)
- Complies with IA-5 (Authenticator Management)

## Network Security Examples

### Non-Compliant: Uncontrolled External Access

```yaml
apiVersion: v1
kind: Service
metadata:
  name: insecure-service
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: frontend
```

**Issues:**
- Uses HTTP instead of HTTPS
- No ingress controller with TLS termination
- No network policies controlling access
- Violates SC-7 (Boundary Protection)
- Violates SC-8 (Transmission Confidentiality and Integrity)

### Compliant: Secure Network Configuration

```yaml
# Network policy restricting access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: secure-network-policy
  namespace: secure-apps
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
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432

---
# TLS ingress for external access
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  namespace: secure-apps
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    linkerd.io/inject: enabled
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: example-tls-cert
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

**Benefits:**
- Uses TLS for external connections
- Specifies allowed hosts
- Implements NetworkPolicy for internal traffic control
- Restricts pod-to-pod communication
- Complies with SC-7 (Boundary Protection)
- Complies with SC-8 (Transmission Confidentiality and Integrity)
- Complies with AC-4 (Information Flow Control)

## Observability Examples

### Non-Compliant: Missing Monitoring

```yaml
# No Linkerd visualization extension installed
# No Prometheus or Grafana configured
```

**Issues:**
- No visibility into service mesh traffic
- No metrics collection
- No audit trail for compliance
- Violates AU-2 (Audit Events)
- Violates AU-3 (Content of Audit Records)
- Violates AU-12 (Audit Generation)
- Violates SI-4 (Information System Monitoring)

### Compliant: Comprehensive Monitoring and Logging

```yaml
# Install Linkerd viz extension
apiVersion: linkerd.io/v1alpha2
kind: Viz
metadata:
  name: linkerd-viz
spec:
  dashboard:
    replicas: 1
  prometheus:
    enabled: true
  grafana:
    enabled: true
  tap:
    enabled: true
  tracing:
    enabled: true

---
# Configure Linkerd proxy with debug logging
apiVersion: linkerd.io/v1alpha2
kind: ControllerConfig
metadata:
  name: linkerd-config
spec:
  proxy:
    logLevel: info
    logFormat: json
```

**Benefits:**
- Comprehensive metrics collection with Prometheus
- Visualization with Grafana dashboards
- Service mesh dashboard
- Tap capability for inspection
- Tracing for request flows
- Structured JSON logs
- Complies with AU-2 (Audit Events)
- Complies with AU-3 (Content of Audit Records)
- Complies with AU-12 (Audit Generation)
- Complies with SI-4 (Information System Monitoring)

## MeshTLS Policy Examples

### Non-Compliant: Missing MeshTLS Policies

```yaml
# No explicit MeshTLS policies
# Relying solely on default automatic mTLS
```

**Issues:**
- No explicit definition of allowed identities
- No fine-grained control over which services can communicate
- Relying solely on default settings
- Potential for unauthorized access

### Compliant: Fine-grained MeshTLS Policies

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLS
metadata:
  name: mesh-tls-auth
  namespace: secure-apps
spec:
  identities:
  - "*.secure-apps.serviceaccount.identity.linkerd.cluster.local"
  - "*.monitoring.serviceaccount.identity.linkerd.cluster.local"
```

**Benefits:**
- Explicit definition of authorized identities
- Fine-grained control over which services can communicate
- Enhanced security through identity-based controls
- Default-deny for identities not specified
- Complies with AC-3 (Access Enforcement)
- Complies with AC-6 (Least Privilege)

## Container Security Examples

### Non-Compliant: Insecure Container Configurations

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: insecure-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: insecure-app
  template:
    metadata:
      labels:
        app: insecure-app
    spec:
      containers:
      - name: app
        image: example/app:latest
        # No resource limits
        # No image pull policy
        securityContext:
          privileged: true
          runAsUser: 0
        # No liveness or readiness probes
```

**Issues:**
- Uses 'latest' tag for container image
- No resource limits (could lead to DoS)
- Runs as privileged container
- Runs as root user (UID 0)
- No image pull policy specified
- No liveness or readiness probes
- No Pod Security Standards enforcement
- Violates CM-7 (Least Functionality)
- Violates SR-3 (Supply Chain Controls and Processes)

### Compliant: Secure Container Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-deployment
  namespace: secure-apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
      annotations:
        linkerd.io/inject: enabled
    spec:
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: example/app:v1.0.0@sha256:abc123...  # Pinned version with digest
        imagePullPolicy: Always
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          runAsUser: 1000
          readOnlyRootFilesystem: true
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

**Benefits:**
- Uses pinned image version with digest
- Always pulls images (prevents using potentially compromised cached images)
- Runs as non-root user
- Drops all capabilities
- Uses read-only root filesystem
- Prevents privilege escalation
- Sets appropriate resource limits and requests
- Implements health and readiness probes
- Explicit service mesh inclusion
- Complies with CM-7 (Least Functionality)
- Complies with SR-3 (Supply Chain Controls and Processes)

## Supply Chain Security Examples

### Non-Compliant: Insecure Supply Chain

```yaml
# No image verification
# No admission controls for image validation
# No SBOM generation
# Using untrusted container registries
# No scanning for vulnerabilities
```

**Issues:**
- No verification of container image integrity
- No validation of container image provenance
- No scanning for vulnerabilities
- Violates SR-3 (Supply Chain Controls and Processes)
- Violates SR-4 (Provenance)
- Violates SR-11 (Component Authenticity)

### Compliant: Secure Supply Chain

```yaml
# Example container image signature verification
apiVersion: v1
kind: ConfigMap
metadata:
  name: cosigned-policy
  namespace: cosign-system
data:
  policy.yaml: |-
    apiVersion: policy.sigstore.dev/v1beta1
    kind: ClusterImagePolicy
    metadata:
      name: require-signatures
    spec:
      images:
      - glob: "**/*"  # Apply to all images
      authorities:
      - name: official-signature
        key:
          secretRef:
            name: cosign-public-key
            namespace: cosign-system
            key: cosign.pub
      - name: sbom-attestation
        attestation:
          name: sbom
          predicateType: https://spdx.dev/Document
```

**Benefits:**
- Verifies container image signatures
- Ensures software provenance
- Requires SBOM attestations
- Enforces validation at admission time
- Complies with SR-3 (Supply Chain Controls and Processes)
- Complies with SR-4 (Provenance)
- Complies with SR-11 (Component Authenticity)
- Complies with CM-14 (Signed Components)

## NIST Controls and Linkerd Implementation

| NIST Control | Description | Linkerd Implementation |
|--------------|-------------|----------------------|
| AC-3 | Access Enforcement | ServerAuthorization resources |
| AC-4 | Information Flow Control | Network policies, ingress configuration |
| AC-6 | Least Privilege | ServerAuthorization policies with specific identity requirements |
| IA-2 | Identification and Authentication (Organizational Users) | Integration with external identity providers |
| IA-3 | Device Identification and Authentication | Service identity, automatic mTLS certificates |
| IA-5 | Authenticator Management | Automatic certificate rotation, identity service |
| IA-8 | Identification and Authentication (Non-Organizational Users) | Ingress integration with external identity providers |
| SC-7 | Boundary Protection | Network policies, ingress/egress control |
| SC-8 | Transmission Confidentiality and Integrity | Automatic mTLS, TLS ingress |
| SC-12 | Cryptographic Key Establishment and Management | Identity service, automatic certificate management |
| SC-13 | Cryptographic Protection | TLS 1.2+, modern cipher suites |
| SC-17 | Public Key Infrastructure Certificates | Workload identity, certificate management |
| AU-2 | Audit Events | Proxy logs, metrics collection |
| AU-3 | Content of Audit Records | Detailed metrics with service context |
| AU-12 | Audit Generation | Linkerd proxy logs and metrics |
| SI-4 | Information System Monitoring | Viz extension with Prometheus, Grafana |
| SR-3 | Supply Chain Controls and Processes | Container image verification and signing |
| SR-4 | Provenance | SBOM and container image provenance |
| SR-11 | Component Authenticity | Cryptographic verification of container images |
| CM-7 | Least Functionality | Pod Security Standards, container hardening |
| CM-14 | Signed Components | Signed container images, secure registries |