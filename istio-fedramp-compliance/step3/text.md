# Auditing Authorization Policies and Network Security

In this step, we'll implement and audit authorization policies and network security controls to meet FedRAMP requirements. NIST SP 800-204B specifically recommends attribute-based access control (ABAC) for microservices, which aligns with Istio's authorization model.

## Background: Authorization in Service Meshes

FedRAMP requires strong authorization controls (AC-3, AC-4, AC-6):

- **Least Privilege** (AC-6): Services should only have access to resources they need
- **Information Flow Control** (AC-4): Traffic between services should be controlled
- **Access Enforcement** (AC-3): Policies should enforce who can access what resources
- **Network Segregation** (SC-7): Network boundaries should be clearly defined

## Task 1: Implement Service-to-Service Authorization Policies

Let's implement authorization policies based on service identity, which aligns with NIST SP 800-204B's recommendation for ABAC:

```bash
cat << EOF | kubectl apply -f -
# Default deny all policy for secure-apps namespace
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: default-deny
  namespace: secure-apps
spec:
  {}
---
# Allow frontend to access backend
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
EOF
```{{exec}}

This implements the principle of least privilege (AC-6) by:
1. Denying all traffic by default
2. Only allowing the frontend service to access the backend service
3. Restricting the allowed HTTP methods to GET only

## Task 2: Verify Authorization Policies

Let's test our authorization policies:

```bash
# Get the frontend pod name
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath={.items..metadata.name})

# This should work - GET from frontend to backend
kubectl exec -n secure-apps $FRONTEND_POD -c httpbin -- curl -s http://backend:80/headers -H "Authorization: Bearer $TOKEN"

# This should fail - POST from frontend to backend (not allowed in policy)
kubectl exec -n secure-apps $FRONTEND_POD -c httpbin -- curl -s -X POST http://backend:80/headers -H "Authorization: Bearer $TOKEN"
```{{exec}}

## Task 3: Implement Network Security Controls

FedRAMP requires boundary protection (SC-7). In a service mesh, we can implement this using Istio's network security features:

```bash
cat << EOF | kubectl apply -f -
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
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "frontend.example.com"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend-vs
  namespace: secure-apps
spec:
  hosts:
  - "frontend.example.com"
  gateways:
  - secure-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: frontend
        port:
          number: 80
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: frontend-dr
  namespace: secure-apps
spec:
  host: frontend
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: backend-dr
  namespace: secure-apps
spec:
  host: backend
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```{{exec}}

This sets up:
1. A secure gateway for external access
2. A VirtualService to route traffic to the frontend
3. DestinationRules to enforce mTLS

## Task 4: Perform a FedRAMP Security Audit

Now, let's create an audit script to check our service mesh for FedRAMP compliance:

```bash
cat << EOF > /root/istio-fedramp-audit.sh
#!/bin/bash

echo "=================================================="
echo "Istio Service Mesh FedRAMP Compliance Audit"
echo "Based on NIST SP 800-53 and NIST SP 800-204 Series"
echo "=================================================="

# Check for mTLS configuration (SC-8, SC-13)
echo
echo "## 1. Transport Encryption Audit (SC-8, SC-13)"
echo "Checking global mTLS policy..."
kubectl get peerauthentication -A

echo
echo "Checking namespace-specific mTLS policies..."
kubectl get peerauthentication -n secure-apps

echo
echo "Checking for non-mTLS traffic..."
istioctl x analyze -n secure-apps --failure-threshold Info

# Check for authorization policies (AC-3, AC-6)
echo
echo "## 2. Authorization Policy Audit (AC-3, AC-6)"
echo "Checking authorization policies..."
kubectl get authorizationpolicy -A

echo
echo "Checking for overly permissive policies..."
kubectl get authorizationpolicy -A -o yaml | grep -A2 action | grep -E "ALLOW$" | wc -l

# Check for network security controls (SC-7, AC-4)
echo
echo "## 3. Network Segmentation Audit (SC-7, AC-4)"
echo "Checking virtual services and gateways..."
kubectl get gateway,virtualservice -A

echo
echo "Checking for default deny policies..."
kubectl get authorizationpolicy -A -o yaml | grep -E "action: DENY|{}" | wc -l

# Check for JWT authentication (IA-2, IA-5)
echo
echo "## 4. Authentication Controls Audit (IA-2, IA-5)"
echo "Checking for JWT authentication..."
kubectl get requestauthentication -A

echo
echo "Checking JWT enforcement with authorization policies..."
kubectl get authorizationpolicy -A -o yaml | grep -A10 rules | grep request.auth.claims

# Check for security monitoring (AU-2, AU-12, SI-4)
echo
echo "## 5. Security Monitoring Audit (AU-2, AU-12, SI-4)"
echo "Checking for Prometheus and Grafana..."
kubectl get pods -n istio-system | grep -E 'prometheus|grafana|kiali'

echo
echo "=================================================="
echo "FedRAMP Compliance Recommendations:"
echo "1. Ensure STRICT mTLS is enforced for all workloads"
echo "2. Implement default deny authorization policies"
echo "3. Apply least privilege for service-to-service communication"
echo "4. Implement JWT authentication for external access"
echo "5. Enable continuous monitoring and logging"
echo "=================================================="
EOF

chmod +x /root/istio-fedramp-audit.sh
```{{exec}}

Let's run the audit script to check our service mesh configuration:

```bash
/root/istio-fedramp-audit.sh
```{{exec}}

## Task 5: Generate FedRAMP Documentation

Let's create a FedRAMP compliance report for our service mesh:

```bash
cat << EOF > /root/istio-fedramp-report.md
# Istio Service Mesh FedRAMP Compliance Report

## Executive Summary

This report documents the security controls implemented in our Istio service mesh to meet FedRAMP Moderate requirements, with specific focus on NIST SP 800-53 controls relevant to service mesh technologies.

## Implemented Security Controls

### Access Control (AC)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| AC-3 | Access Enforcement | Implemented using Istio AuthorizationPolicy resources with specific allow rules |
| AC-4 | Information Flow Control | Implemented using Istio network policies and service-to-service authorization |
| AC-6 | Least Privilege | Implemented by default deny policies and specific allow rules based on service identity |

### Identification and Authentication (IA)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| IA-2 | Identification and Authentication (Organizational Users) | Implemented using JWT authentication for API access |
| IA-3 | Device Identification and Authentication | Implemented using service identity and mTLS certificates |
| IA-5 | Authenticator Management | Implemented using Istio certificate management and rotation |

### System and Communications Protection (SC)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| SC-7 | Boundary Protection | Implemented using Istio Gateways and VirtualServices |
| SC-8 | Transmission Confidentiality and Integrity | Implemented using mTLS encryption |
| SC-13 | Cryptographic Protection | Implemented using TLS 1.2+ and secure cipher suites |

### Audit and Accountability (AU)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| AU-2 | Audit Events | Implemented using Istio access logs |
| AU-3 | Content of Audit Records | Implemented using detailed Istio telemetry |
| AU-12 | Audit Generation | Implemented using Istio proxies that generate audit records |

## Evidence of Compliance

1. **mTLS Configuration**: PeerAuthentication resources enforcing STRICT mode
2. **Authorization Policies**: Default deny and specific allow rules
3. **JWT Authentication**: RequestAuthentication and AuthorizationPolicy enforcement
4. **Network Controls**: Gateway and VirtualService configurations
5. **Monitoring**: Prometheus, Grafana, and Kiali implementations

## Conclusion

The Istio service mesh implementation described in this report satisfies all relevant NIST SP 800-53 controls required for FedRAMP Moderate compliance as they apply to service mesh technologies.

## References

- NIST SP 800-53 Rev. 5
- NIST SP 800-204 Series (Microservices Security)
- Istio Security Best Practices
EOF

echo "Report generated: /root/istio-fedramp-report.md"
```{{exec}}

## NIST Compliance Check

According to NIST SP 800-204B, secure microservices should implement:
1. Strong access control policies
2. Defense-in-depth with multiple security layers
3. Continuous monitoring and logging

Our implementation satisfies these requirements through:
- Comprehensive AuthorizationPolicies with default deny
- Multiple security layers (mTLS, JWT, service identity)
- Integrated monitoring with Prometheus, Grafana, and Kiali

You've now completed the implementation and audit of a FedRAMP-compliant Istio service mesh!