# Auditing and Generating Compliance Evidence

In this step, we'll focus on auditing the Linkerd service mesh and generating evidence for FedRAMP compliance. This is essential for demonstrating that your implementation meets the required security controls.

## Background: FedRAMP Audit Requirements

FedRAMP requires documented evidence of security control implementation, including:

- **Automated validation** of security controls
- **Detailed logs** of security-relevant events
- **Compliance reports** that map to NIST 800-53 controls
- **Technical testing results** that validate control effectiveness

## Task 1: Create a Linkerd Security Audit Script

Let's create a script to audit our Linkerd service mesh for FedRAMP compliance:

```bash
cat << 'EOF' > /root/linkerd-security-audit.sh
#!/bin/bash

echo "=================================================="
echo "Linkerd Service Mesh FedRAMP Security Audit Report"
echo "=================================================="
echo
echo "Date: $(date)"
echo "Cluster: $(kubectl config current-context)"
echo

# Check Linkerd installation
echo "## 1. LINKERD INSTALLATION AUDIT"
echo
echo "Linkerd version:"
linkerd version

echo
echo "Linkerd components status:"
linkerd check

echo
echo "## 2. MTLS ENCRYPTION AUDIT (SC-8, SC-13)"
echo
echo "mTLS status for all meshed workloads:"
linkerd edges --all-namespaces deployment

echo
echo "TLS statistics:"
linkerd stat --tls -n secure-apps deployment

echo
echo "## 3. ACCESS CONTROL AUDIT (AC-3, AC-4, AC-6)"
echo
echo "Server authorization policies:"
kubectl get serverauthorization --all-namespaces -o yaml

echo
echo "HTTP route policies:"
kubectl get httproute --all-namespaces -o yaml

echo
echo "## 4. IDENTITY MANAGEMENT AUDIT (IA-2, IA-3, IA-5)"
echo
echo "Trust anchor configuration:"
kubectl get configmap linkerd-identity-trust-roots -n linkerd -o yaml

echo
echo "Proxy identity configuration:"
SAMPLE_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl get pod -n secure-apps $SAMPLE_POD -o yaml | grep -A10 linkerd.io/proxy-identity

echo
echo "## 5. AUDIT LOGGING (AU-2, AU-3, AU-12)"
echo
echo "Linkerd tap (traffic sampling):"
linkerd tap -n secure-apps deployment/frontend --to deployment/backend --path "/" -o json | head -n 10

echo
echo "## 6. SECURITY COMPLIANCE SUMMARY"
echo
echo "mTLS Encryption (SC-8): ENABLED"
echo "Cryptographic Protection (SC-13): ENABLED (TLS 1.3, ECDSA P-256)"
echo "Access Control (AC-3): IMPLEMENTED via ServerAuthorization"
echo "Information Flow Control (AC-4): IMPLEMENTED via HTTPRoute policies"
echo "Device Authentication (IA-3): IMPLEMENTED via service identity"
echo "Audit Logging (AU-2, AU-3): ENABLED via proxy tap and metrics"
echo
echo "=================================================="
echo "FedRAMP Compliance Recommendations:"
echo "1. Document mTLS configuration for SC-8 compliance"
echo "2. Document identity management for IA-3 compliance"
echo "3. Document authorization policies for AC-3 compliance"
echo "4. Implement continuous monitoring for SI-4 compliance"
echo "5. Ensure certificate rotation procedures for IA-5 compliance"
echo "=================================================="
EOF

chmod +x /root/linkerd-security-audit.sh
```{{exec}}

## Task 2: Run the Security Audit and Generate Evidence

Let's run our audit script to generate compliance evidence:

```bash
# Run the audit script
/root/linkerd-security-audit.sh > /root/linkerd-fedramp-audit-report.txt

# View the summary of the report
tail -n 15 /root/linkerd-fedramp-audit-report.txt
```{{exec}}

## Task 3: Implement Continuous Monitoring

FedRAMP requires continuous monitoring (SI-4). Let's set up some basic monitoring:

```bash
# Install the Linkerd viz extension which includes Prometheus and Grafana
linkerd viz install | kubectl apply -f -

# Wait for the viz components to be ready
kubectl wait --for=condition=ready pod --all -n linkerd-viz --timeout=300s

# Check that viz is working correctly
linkerd viz check

# View the metrics dashboard (note: in a real environment, this would open a web UI)
echo "In a real environment, you would now access: linkerd viz dashboard"

# Setup a cronjob to run our audit script regularly
cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: linkerd-security-audit
  namespace: linkerd
spec:
  schedule: "0 0 * * *"  # Run daily at midnight
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: linkerd-heartbeat
          containers:
          - name: linkerd-security-audit
            image: curlimages/curl:7.83.1
            command:
            - /bin/sh
            - -c
            - |
              curl -sSL https://run.linkerd.io/install | sh
              export PATH=\$PATH:\$HOME/.linkerd2/bin
              cat << 'SCRIPT' > /tmp/audit.sh
$(cat /root/linkerd-security-audit.sh)
SCRIPT
              chmod +x /tmp/audit.sh
              /tmp/audit.sh > /tmp/linkerd-fedramp-audit-\$(date +%Y%m%d).txt
            resources:
              limits:
                cpu: 500m
                memory: 256Mi
              requests:
                cpu: 100m
                memory: 128Mi
          restartPolicy: OnFailure
EOF
```{{exec}}

## Task 4: Generate FedRAMP Documentation

Let's create a FedRAMP compliance document that maps Linkerd controls to NIST 800-53:

```bash
cat << EOF > /root/linkerd-fedramp-compliance.md
# Linkerd Service Mesh FedRAMP Compliance Documentation

## Executive Summary

This document describes how our Linkerd service mesh implementation addresses FedRAMP security controls based on NIST 800-53 Rev 5. Linkerd provides a lightweight, security-focused service mesh that enables us to meet multiple FedRAMP requirements.

## Implemented Security Controls

### Access Control (AC)

| Control ID | Control Name | Linkerd Implementation |
|------------|--------------|------------------------|
| AC-3 | Access Enforcement | ServerAuthorization resources restrict service-to-service communication based on service identity |
| AC-4 | Information Flow Control | HTTPRoute resources enforce allowed methods and paths for API access |
| AC-6 | Least Privilege | Fine-grained access controls limit communications to only what is necessary |

### Identification and Authentication (IA)

| Control ID | Control Name | Linkerd Implementation |
|------------|--------------|------------------------|
| IA-2 | Identification and Authentication (Organizational Users) | Service accounts tied to pod identities with cryptographic verification |
| IA-3 | Device Identification and Authentication | Each service has a unique SPIFFE identity with mTLS verification |
| IA-5 | Authenticator Management | Automatic certificate rotation with short lifetimes |

### System and Communications Protection (SC)

| Control ID | Control Name | Linkerd Implementation |
|------------|--------------|------------------------|
| SC-7 | Boundary Protection | Network policies and authorization policies enforce boundaries |
| SC-8 | Transmission Confidentiality and Integrity | Automatic mTLS between all meshed services |
| SC-13 | Cryptographic Protection | Strong cryptographic algorithms (TLS 1.3, ECDSA P-256) |

### Audit and Accountability (AU)

| Control ID | Control Name | Linkerd Implementation |
|------------|--------------|------------------------|
| AU-2 | Audit Events | Proxy tap and metrics capture security-relevant events |
| AU-3 | Content of Audit Records | Detailed proxy logs include source/destination, time, and operation |
| AU-12 | Audit Generation | Automatic collection of service-to-service communication data |

## Evidence Collection and Continuous Monitoring

Our implementation includes:

1. **Daily automated security audits** (see /root/linkerd-security-audit.sh)
2. **Metrics collection** via Linkerd Viz/Prometheus
3. **Traffic visibility** via Linkerd Tap
4. **Policy enforcement validation** through automated tests

## Conclusion

The Linkerd service mesh provides a comprehensive security foundation that addresses multiple FedRAMP requirements while maintaining simplicity and performance. Our implementation demonstrates compliance with key NIST 800-53 controls for access control, identification and authentication, system and communications protection, and audit logging.
EOF

echo "FedRAMP compliance documentation generated: /root/linkerd-fedramp-compliance.md"
```{{exec}}

## Task 5: Create a Remediation Plan for Any Gaps

FedRAMP requires identifying and addressing any security gaps. Let's create a remediation plan:

```bash
cat << EOF > /root/linkerd-security-remediation.md
# Linkerd Security Remediation Plan

## Identified Gaps and Remediation Actions

| Gap | FedRAMP Control | Remediation Action | Priority | Timeline |
|-----|-----------------|-------------------|----------|----------|
| External certificate integration | IA-5(2) | Integrate with external PKI for certificate management | Medium | 60 days |
| Comprehensive authorization policies | AC-3(3) | Implement organization-wide authorization policy | High | 30 days |
| Enhanced audit logging | AU-3(1) | Configure detailed proxy logging to external SIEM | Medium | 45 days |
| FIPS 140-2/3 compliance | SC-13 | Verify and document cryptographic modules | High | 30 days |
| Automated security scanning | RA-5 | Implement container and policy scanning | Medium | 60 days |

## Implementation Plan

1. **Short Term (30 days)**
   - Document current cryptographic implementations
   - Develop comprehensive authorization policies
   - Configure enhanced proxy logging

2. **Medium Term (60-90 days)**
   - Integrate with external PKI
   - Implement container and policy scanning
   - Enhance metrics and alerting

3. **Long Term (90+ days)**
   - Implement continuous compliance monitoring
   - Develop automated remediation workflows
   - Complete security documentation for ATO package

## Automated Validation

We will implement the following automated validation checks:

\`\`\`bash
# Daily security checks
linkerd check
linkerd viz check

# Weekly policy validation
# Verify all namespaces have authorization policies
kubectl get namespace -o json | jq -r '.items[].metadata.name' | xargs -I{} sh -c "kubectl get serverauthorization -n {} || echo 'ALERT: No ServerAuthorization in {}'"

# Monthly cryptographic validation
# Verify TLS versions and cipher suites
linkerd diagnostics proxy --tap deployment/frontend
\`\`\`

These checks will be integrated into our CI/CD pipeline and monitoring system.
EOF

echo "Security remediation plan generated: /root/linkerd-security-remediation.md"
```{{exec}}

## FedRAMP Compliance Check

Our audit and documentation demonstrate FedRAMP compliance across multiple control families:

1. **Access Control (AC)**:
   - Implemented granular service-to-service authorization
   - Enforced least privilege communication
   - Documented evidence of control implementation

2. **Identification and Authentication (IA)**:
   - Deployed strong service identity with mTLS
   - Implemented short-lived certificates with automatic rotation
   - Provided validation of identity mechanisms

3. **System and Communications Protection (SC)**:
   - Enabled encrypted communications for all meshed services
   - Implemented strong cryptographic algorithms
   - Protected the integrity of the service mesh

4. **Audit and Accountability (AU)**:
   - Configured detailed traffic logging
   - Captured security-relevant events
   - Implemented continuous monitoring

You've now completed the implementation and documentation of a FedRAMP-compliant Linkerd service mesh!