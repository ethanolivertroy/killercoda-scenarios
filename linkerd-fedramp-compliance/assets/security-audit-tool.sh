#!/bin/bash

# Linkerd Service Mesh FedRAMP Compliance Audit Tool
# This script assesses Linkerd service meshes for FedRAMP compliance based on NIST SP 800-53 controls

# Print banner
echo "=================================================="
echo "Linkerd Service Mesh FedRAMP Compliance Audit Tool"
echo "Based on NIST SP 800-53 and NIST SP 800-204 Series"
echo "=================================================="

# Check for Linkerd installation
if ! kubectl get namespace linkerd &>/dev/null; then
  echo "ERROR: Linkerd is not installed. Please install Linkerd first."
  exit 1
fi

# Function to check mTLS configuration
check_mtls() {
  echo
  echo "## 1. TRANSPORT LAYER SECURITY AUDIT (SC-8, SC-13)"
  
  # Check for linkerd identity service
  echo "Checking Linkerd identity service..."
  IDENTITY_SERVICE=$(kubectl get deploy -n linkerd linkerd-identity -o name 2>/dev/null)
  
  if [ -n "$IDENTITY_SERVICE" ]; then
    echo "✅ Linkerd identity service found"
  else
    echo "❌ Linkerd identity service not found"
  fi
  
  # Check trust anchors expiration
  echo
  echo "Checking trust anchor expiration..."
  EXPIRY=$(kubectl get secret linkerd-identity-trust-roots -n linkerd -o jsonpath='{.data.crt-expiry}' 2>/dev/null | base64 -d)
  
  if [ -n "$EXPIRY" ]; then
    echo "✅ Trust anchor expiry: $EXPIRY"
    # Convert expiry date to seconds since epoch
    EXPIRY_SECONDS=$(date -d "$EXPIRY" +%s)
    NOW_SECONDS=$(date +%s)
    DAYS_REMAINING=$(( ($EXPIRY_SECONDS - $NOW_SECONDS) / 86400 ))
    
    if [ "$DAYS_REMAINING" -lt 30 ]; then
      echo "⚠️ WARNING: Trust anchor will expire in less than 30 days!"
    fi
  else
    echo "❌ Could not determine trust anchor expiration"
  fi
  
  # Check meshed namespaces
  echo
  echo "Checking for namespaces with Linkerd injection enabled..."
  MESHED_NS=$(kubectl get ns --show-labels | grep 'linkerd.io/inject=enabled')
  
  if [ -n "$MESHED_NS" ]; then
    echo "✅ Namespaces with automatic injection enabled:"
    echo "$MESHED_NS"
  else
    echo "❌ No namespaces found with automatic Linkerd injection enabled"
  fi
  
  # Check for meshTLS policies
  if kubectl api-resources | grep -q meshtls; then
    echo
    echo "Checking MeshTLS policies..."
    MESHTLS=$(kubectl get meshtls.policy.linkerd.io --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/policy="}{.metadata.name}{", identities="}{.spec.identities[*]}{"\n"}{end}' 2>/dev/null)
    
    if [ -n "$MESHTLS" ]; then
      echo "✅ MeshTLS policies found:"
      echo "$MESHTLS"
    else
      echo "❌ No MeshTLS policies found"
    fi
  fi
  
  # Check proxies for mTLS config
  echo
  echo "Checking for meshed pods with mTLS..."
  MESHED_PODS=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[?(@.metadata.annotations.linkerd\.io/proxy-status)]}{.metadata.namespace}{"/pod="}{.metadata.name}{"\n"}{end}' 2>/dev/null | wc -l)
  
  if [ "$MESHED_PODS" -gt 0 ]; then
    echo "✅ $MESHED_PODS pods found with Linkerd proxy (mTLS enabled by default)"
  else
    echo "❌ No pods found with Linkerd proxy"
  fi
}

# Function to check authorization policies
check_authorization() {
  echo
  echo "## 2. AUTHORIZATION POLICY AUDIT (AC-3, AC-6)"
  
  # Check for ServerAuthorization resources if available
  if kubectl api-resources | grep -q serverauthorization; then
    echo "Checking for ServerAuthorization policies..."
    SERVER_AUTH=$(kubectl get serverauthorization.policy.linkerd.io --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/policy="}{.metadata.name}{", server="}{.spec.server.name}{"\n"}{end}' 2>/dev/null)
    
    if [ -n "$SERVER_AUTH" ]; then
      echo "✅ ServerAuthorization policies found:"
      echo "$SERVER_AUTH"
    else
      echo "❌ No ServerAuthorization policies found"
    fi
    
    # Check for default deny policies
    echo
    echo "Checking for default deny policies..."
    DEFAULT_DENY=$(kubectl get serverauthorization.policy.linkerd.io --all-namespaces -o jsonpath='{range .items[?(@.spec.client.unauthenticated==false)]}{.metadata.namespace}{"/policy="}{.metadata.name}{"\n"}{end}' 2>/dev/null)
    
    if [ -n "$DEFAULT_DENY" ]; then
      echo "✅ Policies that deny unauthenticated requests found:"
      echo "$DEFAULT_DENY"
    else
      echo "❌ No policies that explicitly deny unauthenticated requests found"
    fi
    
    # Count total authorization policies
    echo
    echo "Authorization policy statistics:"
    TOTAL=$(kubectl get serverauthorization.policy.linkerd.io --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | wc -l)
    
    echo "Total ServerAuthorization policies: $TOTAL"
  else
    echo "❌ ServerAuthorization CRD not found - authorization policies not available"
  fi
  
  # Check for NetworkAuthentication resources if available
  if kubectl api-resources | grep -q networkauthentication; then
    echo
    echo "Checking for NetworkAuthentication policies..."
    NETWORK_AUTH=$(kubectl get networkauthentication.policy.linkerd.io --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/policy="}{.metadata.name}{"\n"}{end}' 2>/dev/null)
    
    if [ -n "$NETWORK_AUTH" ]; then
      echo "✅ NetworkAuthentication policies found:"
      echo "$NETWORK_AUTH"
    else
      echo "❌ No NetworkAuthentication policies found"
    fi
  fi
  
  # Check for Kubernetes Network Policies
  echo
  echo "Checking for Kubernetes Network Policies..."
  NETWORK_POLICIES=$(kubectl get networkpolicy --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/policy="}{.metadata.name}{"\n"}{end}')
  
  if [ -n "$NETWORK_POLICIES" ]; then
    echo "✅ Kubernetes Network Policies found:"
    echo "$NETWORK_POLICIES"
  else
    echo "❌ No Kubernetes Network Policies found"
  fi
}

# Function to check network security
check_network() {
  echo
  echo "## 3. NETWORK SECURITY AUDIT (SC-7, AC-4)"
  
  # Check for external connectivity
  echo "Checking for external service configuration..."
  
  # Check for services with type LoadBalancer or NodePort (external exposure)
  EXTERNAL_SVC=$(kubectl get svc --all-namespaces -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer" || @.spec.type=="NodePort")]}{.metadata.namespace}{"/svc="}{.metadata.name}{", type="}{.spec.type}{"\n"}{end}')
  
  if [ -n "$EXTERNAL_SVC" ]; then
    echo "ℹ️ Services exposed externally found:"
    echo "$EXTERNAL_SVC"
  else
    echo "ℹ️ No services exposed externally"
  fi
  
  # Check for Ingress resources
  echo
  echo "Checking for Ingress resources..."
  INGRESS=$(kubectl get ingress --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/ingress="}{.metadata.name}{", hosts="}{.spec.rules[*].host}{"\n"}{end}')
  
  if [ -n "$INGRESS" ]; then
    echo "ℹ️ Ingress resources found:"
    echo "$INGRESS"
  else
    echo "ℹ️ No Ingress resources found"
  fi
  
  # Check for Linkerd SMI resources (if available)
  if kubectl api-resources | grep -q trafficsplit; then
    echo
    echo "Checking for TrafficSplit resources..."
    TRAFFIC_SPLIT=$(kubectl get trafficsplit --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/trafficsplit="}{.metadata.name}{", service="}{.spec.service}{"\n"}{end}' 2>/dev/null)
    
    if [ -n "$TRAFFIC_SPLIT" ]; then
      echo "ℹ️ TrafficSplit resources found:"
      echo "$TRAFFIC_SPLIT"
    else
      echo "ℹ️ No TrafficSplit resources found"
    fi
  fi
  
  # Check for HTTPRoute resources (if available)
  if kubectl api-resources | grep -q httproute; then
    echo
    echo "Checking for HTTPRoute resources..."
    HTTP_ROUTE=$(kubectl get httproute --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/httproute="}{.metadata.name}{"\n"}{end}' 2>/dev/null)
    
    if [ -n "$HTTP_ROUTE" ]; then
      echo "ℹ️ HTTPRoute resources found:"
      echo "$HTTP_ROUTE"
    else
      echo "ℹ️ No HTTPRoute resources found"
    fi
  fi
}

# Function to check authentication
check_authentication() {
  echo
  echo "## 4. AUTHENTICATION AUDIT (IA-2, IA-3, IA-5)"
  
  # Check identity service configuration
  echo "Checking identity service configuration..."
  IDENTITY_CONFIG=$(kubectl get cm linkerd-config -n linkerd -o jsonpath='{.data.values}' 2>/dev/null | grep -A 10 "identity:")
  
  if [ -n "$IDENTITY_CONFIG" ]; then
    echo "✅ Identity service configuration found:"
    echo "$IDENTITY_CONFIG"
  else
    echo "❌ Identity service configuration not found"
  fi
  
  # Check service accounts
  echo
  echo "Checking for service accounts in meshed namespaces..."
  MESHED_NS_LIST=$(kubectl get ns --selector=linkerd.io/inject=enabled -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null)
  
  if [ -n "$MESHED_NS_LIST" ]; then
    for ns in $MESHED_NS_LIST; do
      SA_COUNT=$(kubectl get sa -n "$ns" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | wc -l)
      echo "Namespace $ns has $SA_COUNT service accounts"
    done
  else
    echo "❌ No meshed namespaces found"
  fi
  
  # Check authentication mechanisms in use
  echo
  echo "Checking for external authentication mechanisms..."
  AUTH_MECHANISMS=""
  
  # Check for OAuth2 Proxy
  OAUTH_PROXY=$(kubectl get deploy --all-namespaces -o jsonpath='{range .items[?(@.metadata.name=="oauth2-proxy")]}{.metadata.namespace}{"/deploy="}{.metadata.name}{"\n"}{end}' 2>/dev/null)
  if [ -n "$OAUTH_PROXY" ]; then
    AUTH_MECHANISMS="${AUTH_MECHANISMS}OAuth2-Proxy: $OAUTH_PROXY\n"
  fi
  
  # Check for Authn Policy (if available)
  if kubectl api-resources | grep -q authenticationpolicy; then
    AUTHN_POLICY=$(kubectl get authenticationpolicy --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/policy="}{.metadata.name}{"\n"}{end}' 2>/dev/null)
    if [ -n "$AUTHN_POLICY" ]; then
      AUTH_MECHANISMS="${AUTH_MECHANISMS}AuthenticationPolicy: $AUTHN_POLICY\n"
    fi
  fi
  
  if [ -n "$AUTH_MECHANISMS" ]; then
    echo "✅ External authentication mechanisms found:"
    echo -e "$AUTH_MECHANISMS"
  else
    echo "❌ No external authentication mechanisms found"
  fi
}

# Function to check monitoring
check_monitoring() {
  echo
  echo "## 5. MONITORING AND AUDIT LOGGING (AU-2, AU-12, SI-4)"
  
  # Check for Prometheus
  echo "Checking for Prometheus..."
  PROMETHEUS=$(kubectl get pod -n linkerd-viz -l app=prometheus -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  
  if [ -n "$PROMETHEUS" ]; then
    echo "✅ Prometheus found: $PROMETHEUS"
  else
    echo "❌ Prometheus not found in linkerd-viz namespace"
  fi
  
  # Check for Grafana
  echo
  echo "Checking for Grafana..."
  GRAFANA=$(kubectl get pod -n linkerd-viz -l app=grafana -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  
  if [ -n "$GRAFANA" ]; then
    echo "✅ Grafana found: $GRAFANA"
  else
    echo "❌ Grafana not found in linkerd-viz namespace"
  fi
  
  # Check for Linkerd dashboard
  echo
  echo "Checking for Linkerd dashboard..."
  DASHBOARD=$(kubectl get pod -n linkerd-viz -l app=web -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  
  if [ -n "$DASHBOARD" ]; then
    echo "✅ Linkerd dashboard found: $DASHBOARD"
  else
    echo "❌ Linkerd dashboard not found in linkerd-viz namespace"
  fi
  
  # Check for Tap
  echo
  echo "Checking for Tap API..."
  TAP=$(kubectl get pod -n linkerd-viz -l app=tap -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  
  if [ -n "$TAP" ]; then
    echo "✅ Tap API found: $TAP"
  else
    echo "❌ Tap API not found in linkerd-viz namespace"
  fi
  
  # Check for access logging configuration
  echo
  echo "Checking for access logging configuration..."
  PROXY_LOG_LEVEL=$(kubectl get cm linkerd-config -n linkerd -o jsonpath='{.data.values}' 2>/dev/null | grep -A 2 "proxy:")
  
  if [ -n "$PROXY_LOG_LEVEL" ]; then
    echo "✅ Proxy logging configuration found:"
    echo "$PROXY_LOG_LEVEL"
  else
    echo "❌ Proxy logging configuration not found"
  fi
}

# Function to check container security
check_container_security() {
  echo
  echo "## 6. CONTAINER SECURITY AUDIT (SR-3, SR-4, CM-7)"
  
  # Check for Pod Security Standards
  echo "Checking for Pod Security Standards enforcement..."
  PSS=$(kubectl get ns -L pod-security.kubernetes.io/enforce)
  
  if [[ "$PSS" == *"pod-security.kubernetes.io/enforce"* ]]; then
    echo "✅ Pod Security Standards labels found on namespaces"
    echo "$PSS"
  else
    echo "❌ No Pod Security Standards enforcement found"
  fi
  
  # Check for admission controllers
  echo
  echo "Checking for admission controllers..."
  ADMISSION=$(kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations -o name)
  
  if [ -n "$ADMISSION" ]; then
    echo "✅ Admission webhook configurations found:"
    echo "$ADMISSION"
  else
    echo "❌ No admission webhook configurations found"
  fi
  
  # Check for image pull policy
  echo
  echo "Checking for secure image pull policies..."
  ALWAYS_PULL=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.imagePullPolicy}{"\n"}{end}{end}' | grep -c "Always")
  TOTAL_CONTAINERS=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.name}{"\n"}{end}{end}' | wc -l)
  
  echo "Containers with 'Always' pull policy: $ALWAYS_PULL out of $TOTAL_CONTAINERS"
  if [ "$ALWAYS_PULL" -lt "$TOTAL_CONTAINERS" ]; then
    echo "❌ Not all containers use 'Always' image pull policy"
  else
    echo "✅ All containers use 'Always' image pull policy"
  fi
  
  # Check for resource limits
  echo
  echo "Checking for resource limits..."
  MISSING_LIMITS=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.name}{"\t"}{.resources.limits}{"\n"}{end}{end}' | grep -c "map\[\]")
  
  if [ "$MISSING_LIMITS" -gt 0 ]; then
    echo "❌ $MISSING_LIMITS containers are missing resource limits"
  else
    echo "✅ All containers have resource limits defined"
  fi
}

# Function to check supply chain security
check_supply_chain() {
  echo
  echo "## 7. SUPPLY CHAIN SECURITY AUDIT (SR-3, SR-4, SR-11)"
  
  # Check for image signature verification
  echo "Checking for image signature verification..."
  # This is a simplified check; in a real environment, you'd integrate with tools like Cosign, Notary, etc.
  COSIGN=$(which cosign 2>/dev/null)
  
  if [ -n "$COSIGN" ]; then
    echo "✅ Image signing tool found: $COSIGN"
  else
    echo "❌ No image signing tools (cosign) found"
  fi
  
  # Check for trusted registries
  echo
  echo "Checking for container images from trusted registries..."
  CONTAINER_IMAGES=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' | sort | uniq)
  
  echo "Container images in use:"
  echo "$CONTAINER_IMAGES"
  
  # Check for OCI compliance
  echo
  echo "Checking for OCI-compliant container images..."
  # This is a placeholder. In a real environment, you'd integrate with a scanner.
  echo "❓ Manual verification required for OCI compliance"
  
  # Check for SBOMs
  echo
  echo "Checking for Software Bill of Materials (SBOM)..."
  SYFT=$(which syft 2>/dev/null)
  
  if [ -n "$SYFT" ]; then
    echo "✅ SBOM tool found: $SYFT"
  else
    echo "❌ No SBOM generation tools (syft) found"
  fi
}

# Run all checks
check_mtls
check_authorization
check_network
check_authentication
check_monitoring
check_container_security
check_supply_chain

# Print compliance summary
echo
echo "=================================================="
echo "FedRAMP Compliance Summary:"
echo "1. Transport Security (SC-8, SC-13): $(if [ -n "$IDENTITY_SERVICE" ]; then echo "✅"; else echo "❌"; fi)"
echo "2. Authorization (AC-3, AC-6): $(if kubectl api-resources | grep -q serverauthorization && [ -n "$SERVER_AUTH" ]; then echo "✅"; else echo "❌"; fi)"
echo "3. Network Security (SC-7, AC-4): $(if [ -n "$NETWORK_POLICIES" ]; then echo "✅"; else echo "❌"; fi)"
echo "4. Authentication (IA-2, IA-3, IA-5): $(if [ -n "$IDENTITY_CONFIG" ]; then echo "✅"; else echo "❌"; fi)"
echo "5. Monitoring (AU-2, AU-12, SI-4): $(if [ -n "$PROMETHEUS" ]; then echo "✅"; else echo "❌"; fi)"
echo "6. Container Security (SR-3, CM-7): $(if [[ "$PSS" == *"pod-security.kubernetes.io/enforce"* ]]; then echo "✅"; else echo "❌"; fi)"
echo "7. Supply Chain (SR-3, SR-4): ❓ (requires manual verification)"
echo "=================================================="
echo
echo "FedRAMP Compliance Recommendations:"
echo "1. Ensure Linkerd auto-mTLS is enabled for all workloads"
echo "2. Implement ServerAuthorization policies in all namespaces"
echo "3. Apply fine-grained access controls based on service identity"
echo "4. Implement external authentication for API access"
echo "5. Enable comprehensive monitoring and logging"
echo "6. Enforce Pod Security Standards for all namespaces"
echo "7. Implement container image verification and signing"
echo "8. Generate and maintain Software Bill of Materials (SBOM)"
echo "=================================================="