#!/bin/bash

# Kubernetes FedRAMP Compliance Audit Tool
# This script assesses Kubernetes clusters for FedRAMP compliance based on NIST 800-53 controls

# Print banner
echo "=================================================="
echo "Kubernetes FedRAMP Compliance Audit Tool"
echo "Based on NIST 800-53 Controls"
echo "=================================================="

# Function to check RBAC permissions (AC-2, AC-3, AC-6)
check_rbac() {
  echo
  echo "## ACCESS CONTROL AUDIT (AC-2, AC-3, AC-6)"
  echo "Checking for overly permissive roles..."
  
  # Find roles with wildcards
  WILDCARD_ROLES=$(kubectl get clusterroles -o json | jq -r '.items[] | select(.rules[] | (.resources | index("*")) and (.verbs | index("*"))) | .metadata.name')
  
  if [ -z "$WILDCARD_ROLES" ]; then
    echo "✅ No wildcard roles found"
  else
    echo "❌ Wildcard roles found (potential non-compliance):"
    echo "$WILDCARD_ROLES" | sed 's/^/   - /'
  fi

  # Check service account bindings
  echo
  echo "Checking service account bindings..."
  for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
    for sa in $(kubectl get sa -n $ns -o jsonpath='{.items[*].metadata.name}'); do
      # Get bindings for this service account
      BINDINGS=$(kubectl get rolebinding,clusterrolebinding -A -o json | \
        jq -r --arg ns "$ns" --arg sa "$sa" \
        '.items[] | select(.subjects[]?.kind=="ServiceAccount" and .subjects[]?.name==$sa and .subjects[]?.namespace==$ns) | 
         "   - \(.metadata.name): \(.roleRef.kind)/\(.roleRef.name)"')
      
      if [ ! -z "$BINDINGS" ]; then
        echo "ServiceAccount: $ns/$sa has bindings:"
        echo "$BINDINGS"
      fi
    done
  done
}

# Function to check Pod Security Standards (SC-7, CM-7, AC-6)
check_pod_security() {
  echo
  echo "## POD SECURITY AUDIT (SC-7, CM-7, AC-6)"
  
  # Check for privileged containers
  PRIV_PODS=$(kubectl get pods --all-namespaces -o json | \
    jq -r '.items[] | select(.spec.containers[] | .securityContext.privileged == true) | 
    .metadata.namespace + "/" + .metadata.name')
  
  if [ -z "$PRIV_PODS" ]; then
    echo "✅ No privileged pods found"
  else
    echo "❌ Privileged pods found (FedRAMP non-compliance):"
    echo "$PRIV_PODS" | sed 's/^/   - /'
  fi
  
  # Check for host namespaces
  HOST_NS_PODS=$(kubectl get pods --all-namespaces -o json | \
    jq -r '.items[] | select(.spec.hostNetwork == true or .spec.hostPID == true or .spec.hostIPC == true) | 
    .metadata.namespace + "/" + .metadata.name')
  
  if [ -z "$HOST_NS_PODS" ]; then
    echo "✅ No pods using host namespaces"
  else
    echo "❌ Pods using host namespaces (FedRAMP non-compliance):"
    echo "$HOST_NS_PODS" | sed 's/^/   - /'
  fi
  
  # Check for proper securityContext
  NO_SECURITY_CTX=$(kubectl get pods --all-namespaces -o json | \
    jq -r '.items[] | select((.spec.containers[] | .securityContext == null) or (.spec.securityContext == null)) | 
    .metadata.namespace + "/" + .metadata.name')
  
  if [ -z "$NO_SECURITY_CTX" ]; then
    echo "✅ All pods have security context defined"
  else
    echo "❌ Pods missing security context (potential non-compliance):"
    echo "$NO_SECURITY_CTX" | sed 's/^/   - /'
  fi
}

# Function to check Network Policies (SC-7, AC-4)
check_network_policies() {
  echo
  echo "## NETWORK POLICY AUDIT (SC-7, AC-4)"
  
  # Check namespaces without network policies
  echo "Namespaces without NetworkPolicies (potential compliance issue):"
  MISSING_NETPOL=0
  
  for ns in $(kubectl get ns -o custom-columns=NAME:.metadata.name --no-headers); do
    NETPOL_COUNT=$(kubectl get netpol -n $ns -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null | wc -l)
    if [ $NETPOL_COUNT -eq 0 ]; then
      echo "   - $ns"
      MISSING_NETPOL=1
    fi
  done
  
  if [ $MISSING_NETPOL -eq 0 ]; then
    echo "✅ All namespaces have NetworkPolicies"
  fi
}

# Function to check Secrets Management (IA-5, SC-12, SC-13)
check_secrets() {
  echo
  echo "## SECRETS MANAGEMENT AUDIT (IA-5, SC-12, SC-13)"
  
  # Check for secrets referenced in pod specs
  SECRETS_IN_PODS=$(kubectl get pods --all-namespaces -o json | \
    jq -r '.items[] | select(.spec.containers[].env[]?.valueFrom.secretKeyRef != null) | 
    .metadata.namespace + "/" + .metadata.name')
  
  if [ -z "$SECRETS_IN_PODS" ]; then
    echo "✅ No pods with direct secret references"
  else
    echo "ℹ️ Pods with secret references (requires review for compliance):"
    echo "$SECRETS_IN_PODS" | sed 's/^/   - /'
  fi
  
  # Check for plaintext secrets in environment variables
  PLAINTEXT_SECRETS=$(kubectl get pods --all-namespaces -o json | \
    jq -r '.items[] | .spec.containers[] | .env[] | select(.name | test("pass|key|secret|token|credential";"i")) | 
    "\(.name): \(.value)"')
  
  if [ -z "$PLAINTEXT_SECRETS" ]; then
    echo "✅ No plaintext secrets found in environment variables"
  else
    echo "❌ Potential plaintext secrets found (FedRAMP non-compliance):"
    echo "$PLAINTEXT_SECRETS" | sed 's/^/   - /'
  fi
}

# Function to check Logging and Monitoring (AU-2, AU-3, AU-12)
check_logging() {
  echo
  echo "## LOGGING AND MONITORING AUDIT (AU-2, AU-3, AU-12)"
  
  # Check for log volume mounts
  LOG_MOUNTS=$(kubectl get pods --all-namespaces -o json | \
    jq -r '.items[] | select(.spec.containers[].volumeMounts[]?.name | test(".*log.*";"i")) | 
    .metadata.namespace + "/" + .metadata.name')
  
  if [ -z "$LOG_MOUNTS" ]; then
    echo "ℹ️ No pods with log volume mounts found (requires review)"
  else
    echo "ℹ️ Pods with log volume mounts:"
    echo "$LOG_MOUNTS" | sed 's/^/   - /'
  fi
  
  # Check for cluster-level logging
  if kubectl get ns | grep -q "logging"; then
    echo "✅ Logging namespace exists"
  else
    echo "ℹ️ No dedicated logging namespace found"
  fi
}

# Main function
main() {
  # Run all checks
  check_rbac
  check_pod_security
  check_network_policies
  check_secrets
  check_logging
  
  # Print compliance summary
  echo
  echo "=================================================="
  echo "FedRAMP Compliance Recommendations:"
  echo "1. Implement Pod Security Standards in all namespaces"
  echo "2. Restrict RBAC permissions to follow least privilege"
  echo "3. Apply NetworkPolicies to isolate workloads"
  echo "4. Use Kubernetes Secrets properly, consider external secrets management"
  echo "5. Implement proper logging and monitoring"
  echo "=================================================="
}

# Run the main function
main