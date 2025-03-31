# Linkerd FedRAMP Compliance Examples

This document provides side-by-side comparisons of non-compliant and FedRAMP-compliant Linkerd service mesh configurations.

## Installation Configuration Examples

### Non-Compliant: Basic Installation

```bash
# Default installation with no security enhancements
linkerd install | kubectl apply -f -
```

**Issues:**
- Default certificate validity period too long for IA-5 compliance
- No policy controller for AC-3/AC-4 compliance
- Missing resource limits for DoS protection
- No structured monitoring for SI-4 compliance

### Compliant: Security-Enhanced Installation

```bash
# Generate custom configuration with enhanced security
cat > secure-values.yaml << EOF
identity:
  issuer:
    tls:
      crtPEM: "..."  # CA certificate with limited validity
      keyPEM: "..."  # CA key with strong protection
  externalCA: true
  
# Proxy security settings
proxy:
  enableExternalProfiles: false
  resources:
    cpu:
      limit: "1"
      request: "100m"
    memory:
      limit: "250Mi"
      request: "20Mi"
      
# Enable policy controller
policyController:
  enable: true
EOF

# Install with enhanced security settings
linkerd install --values secure-values.yaml | kubectl apply -f -
```

**Benefits:**
- Shorter certificate validity for IA-5 compliance
- Policy controller for AC-3/AC-4 compliance
- Resource limits to prevent DoS
- Disables external profiles for security
- Complies with SC-8, IA-5, AC-3, and SI-4 controls

## Authorization Policy Examples

### Non-Compliant: No Authorization Policies

```yaml
# No authorization policies defined
# All services can communicate freely within the mesh
```

**Issues:**
- Violates AC-3 (Access Enforcement)
- Violates AC-6 (Least Privilege)
- No granular access control
- No documentation of authorized communication paths

### Compliant: Service-to-Service Authorization

```yaml
# Server definition for backend service
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  name: backend-server
  namespace: secure-apps
spec:
  podSelector:
    matchLabels:
      app: backend
  port: 80
  proxyProtocol: HTTP/1

# Authorization policy for backend service
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  name: backend-server-auth
  namespace: secure-apps
spec:
  server:
    name: backend-server
    namespace: secure-apps
  client:
    # Only allow the frontend service to access backend
    meshTLS:
      serviceAccounts:
        - name: frontend
          namespace: secure-apps
    # Only allow specific HTTP methods
  requiredAuthenticationRefs:
    - name: backend-authn
      kind: MeshTLSAuthentication
      group: policy.linkerd.io
---
apiVersion: policy.linkerd.io/v1beta1
kind: MeshTLSAuthentication
metadata:
  name: backend-authn
  namespace: secure-apps
spec:
  identities:
    - "spiffe://cluster.local/ns/secure-apps/sa/frontend"
```

**Benefits:**
- Implements AC-3 (Access Enforcement)
- Follows AC-6 (Least Privilege)
- Documents authorized communication paths
- Identity-based authentication (IA-2)
- Granular access control

## Network Policy Examples

### Non-Compliant: Missing HTTP Routes

```yaml
# Server and ServerAuthorization without HTTP routes
# No granular control of HTTP methods or paths
```

**Issues:**
- Inadequate for AC-4 (Information Flow Control)
- Allows any HTTP method or path if authorization passes
- Not granular enough for FedRAMP compliance
- Doesn't document authorized operations

### Compliant: HTTP Route Policies

```yaml
# Define allowed HTTP routes
apiVersion: policy.linkerd.io/v1alpha1
kind: HTTPRoute
metadata:
  name: backend-routes
  namespace: secure-apps
spec:
  parentRefs:
  - name: backend-server
    kind: Server
    group: policy.linkerd.io
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: "/api/v1"
      method: GET
    filters:
    - type: URLRewrite
      urlRewrite:
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: "/internal/api"
  - matches:
    - path:
        type: Exact
        value: "/health"
      method: GET
```

**Benefits:**
- Implements AC-4 (Information Flow Control)
- Documents specific authorized operations
- Restricts HTTP methods and paths
- Provides audit trail of allowed operations
- Follows FedRAMP principle of least functionality

## Certificate Management Examples

### Non-Compliant: Default Certificate Configuration

```bash
# Default installation with no certificate customization
# Uses 365-day validity by default
```

**Issues:**
- Certificate validity too long for IA-5 compliance
- No integration with organizational PKI
- No explicit certificate rotation process
- Weak auditability of certificate lifecycle

### Compliant: Enhanced Certificate Management

```bash
# Create custom CA with shorter certificate lifetime
step certificate create root.linkerd.cluster.local root.crt root.key \
  --profile root-ca --no-password --insecure \
  --not-after 8760h

# Create issuer certificate with 30-day lifetime
step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
  --profile intermediate-ca --not-after 720h --no-password --insecure \
  --ca root.crt --ca-key root.key

# Install Linkerd with custom certificates
linkerd install \
  --identity-trust-anchors-file=root.crt \
  --identity-issuer-certificate-file=issuer.crt \
  --identity-issuer-key-file=issuer.key | kubectl apply -f -

# Setup automated certificate rotation
kubectl create job --namespace linkerd linkerd-identity-issuer-renewal-job \
  --from=cronjob/linkerd-identity-issuer-renewal
```

**Benefits:**
- 30-day certificate validity for IA-5 compliance
- Automated certificate rotation for reliability
- Integration with organizational PKI possible
- Auditable certificate management
- Follows FedRAMP certificate management requirements

## Monitoring and Audit Examples

### Non-Compliant: Basic Monitoring

```bash
# Default installation without viz extension
# Limited metrics and no structured logging
```

**Issues:**
- Insufficient for AU-2 (Audit Events)
- Limited visibility for security monitoring
- Inadequate for SI-4 (Information System Monitoring)
- No structured audit records for FedRAMP

### Compliant: Enhanced Monitoring and Audit Logging

```bash
# Install Linkerd viz extension
linkerd viz install | kubectl apply -f -

# Configure logging to external system
cat > proxy-config.yaml << EOF
proxy:
  logLevel: info
  accessLog: "/dev/stdout"
  accessLogFormat: json
EOF

linkerd upgrade --values proxy-config.yaml | kubectl apply -f -

# Setup Prometheus alerts for security events
cat > security-alerts.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: linkerd-security-alerts
  namespace: linkerd-viz
spec:
  groups:
  - name: linkerd-security
    rules:
    - alert: LinkerdCertificateExpiringSoon
      expr: sum(linkerd_identity_cert_expiry_timestamp_seconds) - time() < 604800
      for: 30m
      labels:
        severity: warning
      annotations:
        summary: "Linkerd certificate expiring in less than 7 days"
    - alert: LinkerdUnencryptedTraffic
      expr: sum(linkerd_proxy_inbound_tls_disabled_total) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Linkerd detected unencrypted traffic"
EOF

kubectl apply -f security-alerts.yaml
```

**Benefits:**
- Comprehensive metrics for SI-4 compliance
- Structured audit logs for AU-2/AU-3 compliance
- Alerting for security events
- Monitoring of certificate lifecycle
- Detection of security policy violations
- Meets FedRAMP continuous monitoring requirements

## NIST Controls and Linkerd Implementation

| NIST Control | Description | Linkerd Implementation | Configuration Example |
|--------------|-------------|------------------------|----------------------|
| AC-3 | Access Enforcement | ServerAuthorization resources | `kind: ServerAuthorization` |
| AC-4 | Information Flow Control | HTTPRoute resources | `kind: HTTPRoute` |
| AC-6 | Least Privilege | Fine-grained mesh policies | Specific serviceAccount references |
| IA-2 | Identification and Authentication | Service identity with mTLS | SPIFFE identity format with automatic mTLS |
| IA-5 | Authenticator Management | Certificate rotation | 30-day certificate validity |
| SC-7 | Boundary Protection | Policy enforcement points | Server definitions at service boundaries |
| SC-8 | Transmission Confidentiality and Integrity | Automatic mTLS | Verified by `linkerd edges` |
| SC-13 | Cryptographic Protection | TLS 1.3, ECDSA P-256 | Default cryptographic settings |
| AU-2 | Audit Events | Proxy tap and metrics | Linkerd viz extension |
| AU-3 | Content of Audit Records | Detailed proxy logs | JSON-formatted access logs |
| AU-12 | Audit Generation | Automatic proxy instrumentation | Injected as part of linkerd.io/inject |
| SI-4 | Information System Monitoring | Prometheus metrics and alerts | Linkerd viz with alerting rules |