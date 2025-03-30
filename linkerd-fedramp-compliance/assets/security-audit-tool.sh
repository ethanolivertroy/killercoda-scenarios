#!/bin/bash

# Linkerd Service Mesh FedRAMP Compliance Audit Tool
# This script assesses Linkerd service meshes for FedRAMP compliance based on NIST 800-53 controls

# Print banner
echo "=================================================="
echo "Linkerd Service Mesh FedRAMP Compliance Audit Tool"
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

# Check mTLS configuration
echo
echo "## 2. MTLS ENCRYPTION AUDIT (SC-8, SC-13)"
echo
echo "mTLS status for all meshed workloads:"
linkerd edges --all-namespaces deployment

echo
echo "TLS statistics:"
linkerd stat --tls -n secure-apps deployment 2>/dev/null || echo "No meshed workloads found in secure-apps namespace"

# Check access control
echo
echo "## 3. ACCESS CONTROL AUDIT (AC-3, AC-4, AC-6)"
echo
echo "Server authorization policies:"
kubectl get serverauthorization --all-namespaces -o yaml 2>/dev/null || echo "No ServerAuthorization resources found"

echo
echo "HTTP route policies:"
kubectl get httproute --all-namespaces -o yaml 2>/dev/null || echo "No HTTPRoute resources found"

# Check identity management
echo
echo "## 4. IDENTITY MANAGEMENT AUDIT (IA-2, IA-3, IA-5)"
echo
echo "Trust anchor configuration:"
kubectl get configmap linkerd-identity-trust-roots -n linkerd -o yaml 2>/dev/null || echo "Trust roots not found"

echo
echo "Proxy identity configuration:"
SAMPLE_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$SAMPLE_POD" ]; then
  kubectl get pod -n secure-apps $SAMPLE_POD -o yaml | grep -A10 linkerd.io/proxy-identity || echo "No proxy identity found"
else
  echo "No sample pod found for identity check"
fi

# Check audit logging
echo
echo "## 5. AUDIT LOGGING (AU-2, AU-3, AU-12)"
echo
echo "Linkerd tap (traffic sampling):"
if [ -n "$SAMPLE_POD" ]; then
  linkerd tap -n secure-apps deployment/frontend --to deployment/backend --path "/" -o json --max-rps=1 2>/dev/null || echo "Tap not available or no traffic detected"
else
  echo "No deployments found for tap"
fi

# Print compliance summary
echo
echo "## 6. SECURITY COMPLIANCE SUMMARY"
echo
echo "mTLS Encryption (SC-8): $(linkerd check | grep -q "linkerd-identity" && echo "ENABLED" || echo "NOT ENABLED")"
echo "Access Control (AC-3): $(kubectl get serverauthorization --all-namespaces 2>/dev/null | grep -q "." && echo "IMPLEMENTED" || echo "NOT IMPLEMENTED")"
echo "Information Flow Control (AC-4): $(kubectl get httproute --all-namespaces 2>/dev/null | grep -q "." && echo "IMPLEMENTED" || echo "NOT IMPLEMENTED")"
echo "Device Authentication (IA-3): $(linkerd check | grep -q "linkerd-identity" && echo "IMPLEMENTED" || echo "NOT IMPLEMENTED")"
echo "Audit Logging (AU-2, AU-3): $(kubectl get deployment -n linkerd-viz 2>/dev/null | grep -q "prometheus" && echo "ENABLED" || echo "NOT ENABLED")"
echo
echo "=================================================="
echo "FedRAMP Compliance Recommendations:"
echo "1. Document mTLS configuration for SC-8 compliance"
echo "2. Document identity management for IA-3 compliance"
echo "3. Document authorization policies for AC-3 compliance"
echo "4. Implement continuous monitoring for SI-4 compliance"
echo "5. Ensure certificate rotation procedures for IA-5 compliance"
echo "=================================================="