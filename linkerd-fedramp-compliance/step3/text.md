# Auditing Authorization Policies and Network Security

In this step, we'll audit and enhance our authorization policies and network security controls to meet FedRAMP requirements. NIST SP 800-204B specifically recommends attribute-based access control (ABAC) for microservices.

## Background: Authorization in Service Meshes

FedRAMP requires strong authorization controls (AC-3, AC-4, AC-6):

- **Least Privilege** (AC-6): Services should only have access to resources they need
- **Information Flow Control** (AC-4): Traffic between services should be controlled
- **Access Enforcement** (AC-3): Policies should enforce who can access what resources
- **Network Segregation** (SC-7): Network boundaries should be clearly defined

## Task 1: Audit Existing Authorization Policies

### 1.1 Check Server Authorization Policies

Let's check our existing server authorization policies:

```bash
kubectl get server,serverauthorization -n secure-apps
```{{exec}}

### 1.2 Check Network Policies

Let's also check our existing network policies:

```bash
kubectl get networkpolicy -n secure-apps
```{{exec}}

## Task 2: Enhance Authorization Controls

### 2.1 Add Network Authentication Policies

Let's add network authentication policies to control traffic based on network identity:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1beta1
kind: NetworkAuthentication
metadata:
  name: backend-network-auth
  namespace: secure-apps
spec:
  networks:
  - cidr: "10.0.0.0/8"
    except:
    - "10.1.0.0/16"
EOF
```{{exec}}

### 2.2 Apply More Specific Server Authorizations

Let's create more specific server authorizations to limit access to certain HTTP paths:

```bash
cat <<EOF | kubectl apply -f -
# More specific server authorization for backend
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  name: backend-server-http
  namespace: secure-apps
spec:
  podSelector:
    matchLabels:
      app: backend
  port: 80
  proxyProtocol: HTTP/1
  
---
# Allow frontend to access specific HTTP paths on backend
apiVersion: policy.linkerd.io/v1beta1
kind: HTTPRoute
metadata:
  name: backend-route
  namespace: secure-apps
spec:
  parentRefs:
  - name: backend-server-http
    kind: Server
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /headers
    - path:
        type: PathPrefix
        value: /ip
  backends:
  - name: backend
    port: 80
EOF
```{{exec}}

## Task 3: Test Path-Based Authorization

### 3.1 Test Allowed Paths

Let's test access to allowed paths:

```bash
# Get the frontend pod name
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath={.items..metadata.name})

# Test access to allowed paths
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/headers
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/ip
```{{exec}}

### 3.2 Test Restricted Paths

Now let's test access to a restricted path:

```bash
# Test access to a path that isn't specifically allowed
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/user-agent
```{{exec}}

## Task 4: Perform a FedRAMP Security Audit

### 4.1 Use the Linkerd Audit Tool

Let's use a comprehensive audit script to check our service mesh for FedRAMP compliance:

```bash
chmod +x /root/security-audit-tool.sh
/root/security-audit-tool.sh
```{{exec}}

This script performs a thorough assessment of our Linkerd mesh configuration against FedRAMP requirements.

## Task 5: Generate FedRAMP Documentation

### 5.1 Create Compliance Report

Let's create a FedRAMP compliance report for our service mesh that documents all implemented security controls:

```bash
cat << EOF > /root/linkerd-fedramp-report.md
# Linkerd Service Mesh FedRAMP Compliance Report

## Executive Summary

This report documents the security controls implemented in our Linkerd service mesh to meet FedRAMP Moderate requirements, with specific focus on NIST SP 800-53 controls relevant to service mesh technologies.

## Implemented Security Controls

### Access Control (AC)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| AC-3 | Access Enforcement | Implemented using Linkerd ServerAuthorization resources with specific allow rules |
| AC-4 | Information Flow Control | Implemented using Kubernetes NetworkPolicy and Linkerd authorization |
| AC-6 | Least Privilege | Implemented with specific ServerAuthorization policies based on service identity |

### Identification and Authentication (IA)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| IA-3 | Device Identification and Authentication | Implemented using Linkerd service identity and mTLS certificates |
| IA-5 | Authenticator Management | Implemented using Linkerd certificate management and rotation |

### System and Communications Protection (SC)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| SC-7 | Boundary Protection | Implemented using NetworkPolicies and ingress controls |
| SC-8 | Transmission Confidentiality and Integrity | Implemented using automatic mTLS encryption |
| SC-12 | Cryptographic Key Establishment and Management | Implemented using Linkerd identity service |
| SC-13 | Cryptographic Protection | Implemented using TLS 1.2+ and modern cipher suites |

### Audit and Accountability (AU)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| AU-2 | Audit Events | Implemented using Linkerd access logs and metrics |
| AU-3 | Content of Audit Records | Implemented using detailed Linkerd telemetry |
| AU-12 | Audit Generation | Implemented using Linkerd proxies that generate metrics |

### Supply Chain Risk Management (SR)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| SR-3 | Supply Chain Controls and Processes | Recommendations for container image verification and signing |
| SR-4 | Provenance | Recommendations for SBOM and verified container sources |
| SR-11 | Component Authenticity | Recommendations for cryptographic verification of container images |

### Configuration Management (CM)

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| CM-7 | Least Functionality | Implemented using Pod Security Standards and container hardening |
| CM-14 | Signed Components | Recommendations for signed container images and secure registries |

## Evidence of Compliance

1. **mTLS Configuration**: Automatic mTLS for all meshed services
2. **Authorization Policies**: ServerAuthorization with specific identity requirements
3. **Network Controls**: Network policies and Server resources
4. **Monitoring**: Prometheus, Grafana, and Linkerd dashboard
5. **Container Security**: Pod Security Standards enforcement
6. **Supply Chain Security**: Recommendations for image signing and verification

## Conclusion

The Linkerd service mesh implementation described in this report satisfies all relevant NIST SP 800-53 controls required for FedRAMP Moderate compliance as they apply to service mesh technologies, including the latest container security and supply chain security controls per NIST SP 800-204D.

## References

- NIST SP 800-53 Rev. 5: Security and Privacy Controls
- NIST SP 800-204: Security Strategies for Microservices
- NIST SP 800-204A: Building Secure Microservices-based Applications
- NIST SP 800-204B: Attribute-based Access Control for Microservices
- NIST SP 800-204C: Implementation of DevSecOps for Microservices
- NIST SP 800-204D: Security Strategies for Container Runtimes and Orchestration in Microservices
- Linkerd Security Best Practices
EOF

echo "Report generated: /root/linkerd-fedramp-report.md"
```{{exec}}

### 5.2 Review Generated Report

Let's view the generated compliance report:

```bash
cat /root/linkerd-fedramp-report.md | head -n 20
```{{exec}}

## Task 6: Implement Container and Supply Chain Security

The latest NIST SP 800-204D publication emphasizes container security in microservices environments. When implementing Linkerd in a FedRAMP environment, you should also consider these critical security controls:

### 6.1 Apply Container Security Controls (SR-3, SR-4, CM-7)

```bash
# Add Pod Security Standards enforcement to the secure-apps namespace
kubectl label namespace secure-apps pod-security.kubernetes.io/enforce=restricted

# Verify the label
kubectl get namespace secure-apps --show-labels
```{{exec}}

### 6.2 Supply Chain Security Recommendations

For a fully compliant FedRAMP implementation, consider these additional security measures:

1. **Container Image Scanning**: Scan all container images for vulnerabilities before deployment
2. **Image Signing**: Implement digital signatures for container images using tools like Cosign
3. **Software Bill of Materials (SBOM)**: Generate and maintain SBOMs for all container images
4. **Immutable Infrastructure**: Use immutable container configurations
5. **Secure Registries**: Source containers only from approved, secure registries
6. **Resource Limits**: Enforce CPU and memory limits for all containers

## Task 7: Verify Linkerd Dashboard

The Linkerd dashboard provides monitoring and observability capabilities required for FedRAMP compliance. Let's check it:

```bash
# Check that the dashboard is running
kubectl get deploy -n linkerd-viz web

# Check dashboard access (in a live environment, this would be secured with authentication)
linkerd viz dashboard --port 8084 &
```{{exec}}

The dashboard would be used for monitoring and auditing your service mesh in a production environment.

## Task 8: Run Extended Security Audit

### 8.1 Execute Comprehensive Compliance Audit

Run our comprehensive security audit script again to check for NIST SP 800-204D compliance:

```bash
/root/security-audit-tool.sh
```{{exec}}

This audit incorporates the latest NIST guidance, including container and supply chain security controls.

## Compliance Summary

Our Linkerd implementation now meets FedRAMP requirements by:

1. **Using automatic mTLS** for service-to-service encryption (SC-8, SC-13)
2. **Implementing identity-based authorization** with ServerAuthorization (AC-3, AC-6)
3. **Enforcing network segmentation** with NetworkPolicies (SC-7, AC-4)
4. **Providing comprehensive monitoring** with Linkerd Viz (AU-2, AU-12, SI-4)
5. **Supporting least privilege** with fine-grained access controls (AC-6)
6. **Enabling automated certificate management** (SC-12, SC-17, IA-5)
7. **Securing container workloads** with Pod Security Standards (SR-3, CM-7)

You've now completed the implementation and audit of a FedRAMP-compliant Linkerd service mesh that incorporates the latest NIST guidance!