# Service Mesh FedRAMP Compliance Examples

This document provides examples of compliant and non-compliant configurations for Istio service meshes in the context of FedRAMP requirements.

## mTLS Configuration Examples

### Non-Compliant: Permissive or Disabled mTLS

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: PERMISSIVE
```

**Issues:**
- Allows both plaintext and mTLS traffic
- Violates SC-8 (Transmission Confidentiality and Integrity)
- Does not enforce strong authentication between services

### Compliant: Strict mTLS

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

**Benefits:**
- Enforces encrypted communications for all service-to-service traffic
- Ensures mutual authentication between services
- Complies with SC-8 (Transmission Confidentiality and Integrity)
- Complies with SC-13 (Cryptographic Protection)
- Complies with IA-3 (Device Identification and Authentication)

## Authorization Policy Examples

### Non-Compliant: No Authorization Policies

```yaml
# No authorization policies defined
# This means all authenticated services can communicate with each other
```

**Issues:**
- Violates AC-3 (Access Enforcement)
- Violates AC-6 (Least Privilege)
- Allows any authenticated service to access any other service
- No fine-grained access control

### Compliant: Default Deny with Specific Allows

```yaml
# Default deny all traffic
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: default-deny
  namespace: secure-apps
spec:
  {}
---
# Allow specific service-to-service communication
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: secure-apps
spec:
  selector:
    matchLabels:
      app: backend
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/secure-apps/sa/frontend"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api/*"]
```

**Benefits:**
- Implements least privilege principle
- Denies all traffic by default
- Only allows specific, well-defined communication paths
- Restricts allowed HTTP methods and paths
- Complies with AC-3 (Access Enforcement)
- Complies with AC-6 (Least Privilege)
- Complies with AC-4 (Information Flow Control)

## Authentication Examples

### Non-Compliant: Missing JWT Authentication

```yaml
# No RequestAuthentication resources defined
# No JWT validation or enforcement
```

**Issues:**
- No user/client authentication
- Relies solely on service identity (insufficient for user-facing services)
- Violates IA-2 (Identification and Authentication)
- Violates IA-5 (Authenticator Management)
- Violates IA-8 (Identification and Authentication of Non-Organizational Users)

### Compliant: JWT Authentication with Enforcement

```yaml
# Define JWT validation
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-authentication
  namespace: secure-apps
spec:
  selector:
    matchLabels:
      app: backend
  jwtRules:
  - issuer: "https://auth.example.com"
    jwksUri: "https://auth.example.com/.well-known/jwks.json"
    audiences: ["https://api.example.com"]
---
# Enforce JWT validation
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: secure-apps
spec:
  selector:
    matchLabels:
      app: backend
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["*"]
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/*"]
    when:
    - key: request.auth.claims[iss]
      values: ["https://auth.example.com"]
    - key: request.auth.claims[exp]
      notValues: ["0"]
```

**Benefits:**
- Validates JWT tokens from authenticated users/clients
- Enforces token validation with authorization policy
- Checks token issuer and expiration
- Complies with IA-2 (Identification and Authentication)
- Complies with IA-5 (Authenticator Management)
- Complies with IA-8 (Identification and Authentication - Non-Organizational Users)
- Complies with AC-3 (Access Enforcement)

## Network Security Examples

### Non-Compliant: Uncontrolled External Access

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: insecure-gateway
  namespace: default
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: wide-open-routing
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - insecure-gateway
  http:
  - route:
    - destination:
        host: backend
        port:
          number: 80
```

**Issues:**
- Uses HTTP instead of HTTPS
- Allows access from any host
- No TLS configuration
- No traffic routing restrictions
- Violates SC-7 (Boundary Protection)
- Violates SC-8 (Transmission Confidentiality and Integrity)

### Compliant: Secure Gateway and Routing

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: secure-gateway
  namespace: secure-apps
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "api.example.com"
    tls:
      mode: SIMPLE
      credentialName: example-com-cert
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: secure-routing
  namespace: secure-apps
spec:
  hosts:
  - "api.example.com"
  gateways:
  - secure-gateway
  http:
  - match:
    - uri:
        prefix: "/api/v1"
    route:
    - destination:
        host: frontend
        port:
          number: 80
  - match:
    - uri:
        prefix: "/health"
    route:
    - destination:
        host: frontend
        port:
          number: 80
```

**Benefits:**
- Uses HTTPS instead of HTTP
- Specifies allowed hosts
- Uses TLS certificate
- Defines specific URI paths for routing
- Complies with SC-7 (Boundary Protection)
- Complies with SC-8 (Transmission Confidentiality and Integrity)
- Complies with AC-4 (Information Flow Control)

## Certificate Management Examples

### Non-Compliant: Manual or Missing Certificate Management

```yaml
# No automated certificate management
# Manual certificate generation and distribution
# No certificate rotation policy
# No validation of certificate provenance
```

**Issues:**
- Manual certificate management prone to errors
- No automatic certificate rotation
- Risk of expired certificates
- No centralized control over certificate lifecycle
- Violates SC-12 (Cryptographic Key Establishment and Management)
- Violates SC-17 (Public Key Infrastructure Certificates)
- Violates IA-5 (Authenticator Management)

### Compliant: Automated Certificate Management

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  # Secure CA (istiod) configuration
  components:
    pilot:
      k8s:
        env:
          # Set the grace period for workload certificate rotation
          - name: PILOT_CERT_PROVIDER
            value: "istiod"
          - name: PILOT_MAX_WORKLOAD_CERT_TTL
            value: "24h"    # Max certificate lifetime
          - name: PILOT_WORKLOAD_CERT_TTL
            value: "21h"    # Default certificate lifetime
          - name: PILOT_WORKLOAD_CERT_MIN_GRACE
            value: "3h"     # Minimum time before expiration for rotation
  values:
    global:
      # Use the Kubernetes service account as identity
      caAddress: istiod.istio-system.svc:15012
      pilotCertProvider: istiod
```

**Benefits:**
- Automated certificate generation and distribution
- Automatic rotation before expiration
- Centralized certificate management
- Secured certificate signing and validation
- Complies with SC-12 (Cryptographic Key Establishment and Management)
- Complies with SC-17 (Public Key Infrastructure Certificates)
- Complies with IA-5 (Authenticator Management)

## Monitoring and Audit Examples

### Non-Compliant: Missing Monitoring

```yaml
# No monitoring components deployed
# No access logging configuration
```

**Issues:**
- No visibility into service mesh traffic
- No audit trail for compliance
- Violates AU-2 (Audit Events)
- Violates AU-3 (Content of Audit Records)
- Violates AU-12 (Audit Generation)
- Violates SI-4 (Information System Monitoring)

### Compliant: Comprehensive Monitoring and Logging

```yaml
# Istio mesh configuration with access logging
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: "/dev/stdout"
    accessLogFormat: |
      {
        "protocol": "%PROTOCOL%",
        "upstream_service_time": "%REQ(X-ENVOY-UPSTREAM-SERVICE-TIME)%",
        "upstream_local_address": "%UPSTREAM_LOCAL_ADDRESS%",
        "duration": "%DURATION%",
        "request_method": "%REQ(:METHOD)%",
        "request_path": "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%",
        "response_code": "%RESPONSE_CODE%",
        "response_flags": "%RESPONSE_FLAGS%",
        "x_forwarded_for": "%REQ(X-FORWARDED-FOR)%",
        "user_agent": "%REQ(USER-AGENT)%",
        "request_id": "%REQ(X-REQUEST-ID)%",
        "authority": "%REQ(:AUTHORITY)%",
        "upstream_host": "%UPSTREAM_HOST%",
        "source_address": "%DOWNSTREAM_REMOTE_ADDRESS_WITHOUT_PORT%",
        "source_namespace": "%UPSTREAM_PEER_PRINCIPAL%"
      }
# Prometheus and Grafana for monitoring
---
# Deploy Prometheus, Grafana, and Kiali for monitoring
# (These would be included via standard Istio addons)
```

**Benefits:**
- Comprehensive access logging
- Monitoring with Prometheus, Grafana, and Kiali
- Detailed log format with security-relevant fields
- Complies with AU-2 (Audit Events)
- Complies with AU-3 (Content of Audit Records)
- Complies with AU-12 (Audit Generation)
- Complies with SI-4 (Information System Monitoring)

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

## NIST Controls and Istio Implementation

| NIST Control | Description | Istio Implementation |
|--------------|-------------|----------------------|
| AC-3 | Access Enforcement | AuthorizationPolicy resources |
| AC-4 | Information Flow Control | Network policies, VirtualService rules |
| AC-6 | Least Privilege | Default deny policies, specific allow rules |
| IA-2 | Identification and Authentication (Organizational Users) | JWT authentication |
| IA-3 | Device Identification and Authentication | Service identity, mTLS certificates |
| IA-5 | Authenticator Management | Certificate rotation, JWT validation |
| IA-8 | Identification and Authentication (Non-Organizational Users) | Ingress Gateway with JWT RequestAuthentication |
| SC-7 | Boundary Protection | Gateway configuration, ingress/egress control |
| SC-8 | Transmission Confidentiality and Integrity | mTLS encryption, HTTPS gateways |
| SC-12 | Cryptographic Key Establishment and Management | Istio certificate management (istiod) |
| SC-13 | Cryptographic Protection | TLS 1.2+, FIPS-compliant cipher suites |
| SC-17 | Public Key Infrastructure Certificates | SPIFFE SVIDs, workload certificate management |
| AU-2 | Audit Events | Access logging configuration |
| AU-3 | Content of Audit Records | Detailed log format with required fields |
| AU-12 | Audit Generation | Envoy proxy access logs |
| SI-4 | Information System Monitoring | Prometheus, Grafana, Kiali monitoring |
| SR-3 | Supply Chain Controls and Processes | Container image verification and signing |
| SR-4 | Provenance | SBOM and container image provenance |
| SR-11 | Component Authenticity | Cryptographic verification of container images |
| CM-7 | Least Functionality | Pod Security Standards, container hardening |
| CM-14 | Signed Components | Signed container images, secure registries |