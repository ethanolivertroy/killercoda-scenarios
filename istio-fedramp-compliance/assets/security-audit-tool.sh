#!/bin/bash

# Istio Service Mesh FedRAMP Compliance Audit Tool
# This script assesses Istio service meshes for FedRAMP compliance based on NIST SP 800-53 controls

# Print banner
echo "=================================================="
echo "Istio Service Mesh FedRAMP Compliance Audit Tool"
echo "Based on NIST SP 800-53 and NIST SP 800-204 Series"
echo "=================================================="

# Check for Istio installation
if ! kubectl get namespace istio-system &>/dev/null; then
  echo "ERROR: Istio is not installed. Please install Istio first."
  exit 1
fi

# Function to check mTLS configuration
check_mtls() {
  echo
  echo "## 1. TRANSPORT LAYER SECURITY AUDIT (SC-8, SC-13)"
  
  # Check for global PeerAuthentication policy
  echo "Checking global mTLS policy..."
  GLOBAL_MTLS=$(kubectl get peerauthentication -n istio-system -o jsonpath='{.items[?(@.metadata.name=="default")].spec.mtls.mode}')
  
  if [ "$GLOBAL_MTLS" == "STRICT" ]; then
    echo "✅ Global STRICT mTLS policy found"
  else
    echo "❌ No global STRICT mTLS policy found"
  fi
  
  # Check for namespace-specific policies
  echo
  echo "Checking namespace-specific mTLS policies..."
  NS_POLICIES=$(kubectl get peerauthentication --all-namespaces -o jsonpath='{range .items[?(@.metadata.namespace!="istio-system")]}{.metadata.namespace}{": "}{.spec.mtls.mode}{"\n"}{end}')
  
  if [ -z "$NS_POLICIES" ]; then
    echo "ℹ️ No namespace-specific mTLS policies found"
  else
    echo "$NS_POLICIES"
  fi
  
  # Check workload-specific policies
  echo
  echo "Checking workload-specific mTLS policies..."
  WL_POLICIES=$(kubectl get peerauthentication --all-namespaces -o jsonpath='{range .items[?(@.spec.selector)]}{.metadata.namespace}{"/workload="}{.spec.selector.matchLabels.app}{": "}{.spec.mtls.mode}{"\n"}{end}')
  
  if [ -z "$WL_POLICIES" ]; then
    echo "ℹ️ No workload-specific mTLS policies found"
  else
    echo "$WL_POLICIES"
  fi
  
  # Check DestinationRules for TLS settings
  echo
  echo "Checking DestinationRules for TLS settings..."
  DR_TLS=$(kubectl get destinationrule --all-namespaces -o jsonpath='{range .items[?(@.spec.trafficPolicy.tls)]}{.metadata.namespace}{"/destinationrule="}{.metadata.name}{": "}{.spec.trafficPolicy.tls.mode}{"\n"}{end}')
  
  if [ -z "$DR_TLS" ]; then
    echo "ℹ️ No DestinationRules with TLS settings found"
  else
    echo "$DR_TLS"
  fi
}

# Function to check authorization policies
check_authorization() {
  echo
  echo "## 2. AUTHORIZATION POLICY AUDIT (AC-3, AC-6)"
  
  # Check for default deny policies
  echo "Checking for default deny policies..."
  DEFAULT_DENY=$(kubectl get authorizationpolicy --all-namespaces -o jsonpath='{range .items[?(@.spec.action=="DENY" || @.spec.action=="")]}{.metadata.namespace}{"/policy="}{.metadata.name}{"\n"}{end}')
  
  if [ -z "$DEFAULT_DENY" ]; then
    echo "❌ No default deny policies found"
  else
    echo "$DEFAULT_DENY"
  fi
  
  # Check for overly permissive policies
  echo
  echo "Checking for overly permissive policies..."
  PERMISSIVE_POLICIES=$(kubectl get authorizationpolicy --all-namespaces -o jsonpath='{range .items[?(@.spec.action=="ALLOW" && @.spec.rules[0].to==null)]}{.metadata.namespace}{"/policy="}{.metadata.name}{"\n"}{end}')
  
  if [ -z "$PERMISSIVE_POLICIES" ]; then
    echo "✅ No overly permissive policies found"
  else
    echo "❌ Potentially overly permissive policies found:"
    echo "$PERMISSIVE_POLICIES"
  fi
  
  # Count total authorization policies
  echo
  echo "Authorization policy statistics:"
  TOTAL=$(kubectl get authorizationpolicy --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | wc -l)
  ALLOW=$(kubectl get authorizationpolicy --all-namespaces -o jsonpath='{range .items[?(@.spec.action=="ALLOW")]}{.metadata.name}{"\n"}{end}' | wc -l)
  DENY=$(kubectl get authorizationpolicy --all-namespaces -o jsonpath='{range .items[?(@.spec.action=="DENY")]}{.metadata.name}{"\n"}{end}' | wc -l)
  DEFAULT=$(kubectl get authorizationpolicy --all-namespaces -o jsonpath='{range .items[?(@.spec.action=="")]}{.metadata.name}{"\n"}{end}' | wc -l)
  
  echo "Total policies: $TOTAL"
  echo "ALLOW policies: $ALLOW"
  echo "DENY policies: $DENY"
  echo "Default (DENY) policies: $DEFAULT"
}

# Function to check network security
check_network() {
  echo
  echo "## 3. NETWORK SECURITY AUDIT (SC-7, AC-4)"
  
  # Check for gateways
  echo "Checking for Istio Gateways..."
  GATEWAYS=$(kubectl get gateway --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/gateway="}{.metadata.name}{"\n"}{end}')
  
  if [ -z "$GATEWAYS" ]; then
    echo "ℹ️ No Istio Gateways found"
  else
    echo "$GATEWAYS"
  fi
  
  # Check for VirtualServices
  echo
  echo "Checking for VirtualServices..."
  VS=$(kubectl get virtualservice --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/vs="}{.metadata.name}{", hosts="}{.spec.hosts[*]}{"\n"}{end}')
  
  if [ -z "$VS" ]; then
    echo "ℹ️ No VirtualServices found"
  else
    echo "$VS"
  fi
  
  # Check for ServiceEntries
  echo
  echo "Checking for ServiceEntries (external service definitions)..."
  SE=$(kubectl get serviceentry --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/serviceentry="}{.metadata.name}{", hosts="}{.spec.hosts[*]}{"\n"}{end}')
  
  if [ -z "$SE" ]; then
    echo "ℹ️ No ServiceEntries found"
  else
    echo "$SE"
  fi
  
  # Check for Sidecars
  echo
  echo "Checking for Sidecar resources (egress control)..."
  SIDECARS=$(kubectl get sidecar --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/sidecar="}{.metadata.name}{"\n"}{end}')
  
  if [ -z "$SIDECARS" ]; then
    echo "ℹ️ No Sidecar resources found"
  else
    echo "$SIDECARS"
  fi
}

# Function to check authentication
check_authentication() {
  echo
  echo "## 4. AUTHENTICATION AUDIT (IA-2, IA-3, IA-5)"
  
  # Check for RequestAuthentication
  echo "Checking for RequestAuthentication resources..."
  REQUEST_AUTH=$(kubectl get requestauthentication --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/auth="}{.metadata.name}{", issuer="}{.spec.jwtRules[0].issuer}{"\n"}{end}')
  
  if [ -z "$REQUEST_AUTH" ]; then
    echo "❌ No RequestAuthentication resources found"
  else
    echo "$REQUEST_AUTH"
  fi
  
  # Check for JWT enforcement
  echo
  echo "Checking for JWT enforcement in AuthorizationPolicy..."
  JWT_ENFORCE=$(kubectl get authorizationpolicy --all-namespaces -o yaml | grep -A5 "requestPrincipals\|request.auth.claims")
  
  if [ -z "$JWT_ENFORCE" ]; then
    echo "❌ No JWT enforcement found in AuthorizationPolicy resources"
  else
    echo "✅ JWT enforcement found in AuthorizationPolicy resources"
  fi
  
  # Check for origin authentication
  echo
  echo "Checking for origin authentication controls..."
  ORIGIN_AUTH=$(kubectl get authorizationpolicy --all-namespaces -o yaml | grep -A5 "source.ip\|source.namespace\|source.principal")
  
  if [ -z "$ORIGIN_AUTH" ]; then
    echo "❌ No source-based authentication controls found"
  else
    echo "✅ Source-based authentication controls found"
  fi
}

# Function to check monitoring
check_monitoring() {
  echo
  echo "## 5. MONITORING AND AUDIT LOGGING (AU-2, AU-12, SI-4)"
  
  # Check for Prometheus
  echo "Checking for Prometheus..."
  PROMETHEUS=$(kubectl get pod -n istio-system -l app=prometheus -o jsonpath='{.items[*].metadata.name}')
  
  if [ -z "$PROMETHEUS" ]; then
    echo "❌ Prometheus not found in istio-system namespace"
  else
    echo "✅ Prometheus found: $PROMETHEUS"
  fi
  
  # Check for Grafana
  echo
  echo "Checking for Grafana..."
  GRAFANA=$(kubectl get pod -n istio-system -l app=grafana -o jsonpath='{.items[*].metadata.name}')
  
  if [ -z "$GRAFANA" ]; then
    echo "❌ Grafana not found in istio-system namespace"
  else
    echo "✅ Grafana found: $GRAFANA"
  fi
  
  # Check for Kiali
  echo
  echo "Checking for Kiali..."
  KIALI=$(kubectl get pod -n istio-system -l app=kiali -o jsonpath='{.items[*].metadata.name}')
  
  if [ -z "$KIALI" ]; then
    echo "❌ Kiali not found in istio-system namespace"
  else
    echo "✅ Kiali found: $KIALI"
  fi
  
  # Check for access logging configuration
  echo
  echo "Checking for access logging configuration..."
  ACCESS_LOG=$(kubectl get cm istio -n istio-system -o jsonpath='{.data.mesh}' 2>/dev/null | grep accessLogFile)
  
  if [ -z "$ACCESS_LOG" ]; then
    echo "❌ Access logging not explicitly configured"
  else
    echo "✅ Access logging configured: $ACCESS_LOG"
  fi
}

# Run all checks
check_mtls
check_authorization
check_network
check_authentication
check_monitoring

# Print compliance summary
echo
echo "=================================================="
echo "FedRAMP Compliance Summary:"
echo "1. Transport Security (SC-8, SC-13): $(if [ "$GLOBAL_MTLS" == "STRICT" ]; then echo "✅"; else echo "❌"; fi)"
echo "2. Authorization (AC-3, AC-6): $(if [ ! -z "$DEFAULT_DENY" ]; then echo "✅"; else echo "❌"; fi)"
echo "3. Network Security (SC-7, AC-4): $(if [ ! -z "$GATEWAYS" ]; then echo "✅"; else echo "❌"; fi)"
echo "4. Authentication (IA-2, IA-3, IA-5): $(if [ ! -z "$REQUEST_AUTH" ]; then echo "✅"; else echo "❌"; fi)"
echo "5. Monitoring (AU-2, AU-12, SI-4): $(if [ ! -z "$PROMETHEUS" ]; then echo "✅"; else echo "❌"; fi)"
echo "=================================================="
echo
echo "FedRAMP Compliance Recommendations:"
echo "1. Ensure STRICT mTLS is enforced for all workloads"
echo "2. Implement default deny authorization policies in all namespaces"
echo "3. Apply fine-grained access controls based on service identity"
echo "4. Implement JWT authentication for external API access"
echo "5. Enable comprehensive monitoring and logging"
echo "=================================================="