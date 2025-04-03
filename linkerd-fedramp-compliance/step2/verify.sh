#!/bin/bash

# More resilient verification script
echo "Verifying mTLS and security policies..."

# Check 1: Verify the namespace exists and is annotated for Linkerd
if ! kubectl get namespace secure-apps &>/dev/null; then
  echo "❌ The secure-apps namespace doesn't exist. Please create it."
  exit 1
fi

if ! kubectl get namespace secure-apps -o jsonpath='{.metadata.annotations.linkerd\.io/inject}' | grep -q enabled; then
  echo "❌ The secure-apps namespace is not annotated for Linkerd injection."
  exit 1
fi

# Check 2: Verify the deployments exist and are running
FRONTEND_POD_COUNT=$(kubectl get pods -n secure-apps -l app=frontend --field-selector status.phase=Running 2>/dev/null | grep -c frontend || echo 0)
BACKEND_POD_COUNT=$(kubectl get pods -n secure-apps -l app=backend --field-selector status.phase=Running 2>/dev/null | grep -c backend || echo 0)

if [ "$FRONTEND_POD_COUNT" -eq 0 ] || [ "$BACKEND_POD_COUNT" -eq 0 ]; then
  echo "❌ The frontend or backend pods are not running. Please check your deployments."
  exit 1
fi

# Check 3: Verify ConfigMap exists
if ! kubectl get configmap backend-content -n secure-apps &>/dev/null; then
  echo "❌ The backend-content ConfigMap is missing."
  exit 1
fi

# Check 4: Verify the Server resource exists (try both API versions for compatibility)
echo "Checking for Server resource..."
SERVER_EXISTS=false
if kubectl get server.policy.linkerd.io backend-server -n secure-apps &>/dev/null; then
  SERVER_EXISTS=true
  echo "✅ Found Server resource 'backend-server' (policy.linkerd.io API)"
elif kubectl get server backend-server -n secure-apps &>/dev/null; then
  SERVER_EXISTS=true
  echo "✅ Found Server resource 'backend-server' (core API)"
fi

if [ "$SERVER_EXISTS" = false ]; then
  echo "❌ The Server resource 'backend-server' is missing."
  echo "Available Server CRDs:"
  kubectl api-resources | grep -i server
  exit 1
fi

# Check 5: Verify the ServerAuthorization resource exists (try all possible API versions for compatibility)
echo "Checking for ServerAuthorization resource..."
AUTH_EXISTS=false

# Try with all possible API group combinations
for API_GROUP in "policy.linkerd.io" "linkerd.io" ""; do
  if [ -n "$API_GROUP" ]; then
    RESOURCE="serverauthorization.$API_GROUP"
  else
    RESOURCE="serverauthorization"
  fi
  
  if kubectl get $RESOURCE backend-server-auth -n secure-apps &>/dev/null; then
    AUTH_EXISTS=true
    echo "✅ Found ServerAuthorization resource 'backend-server-auth' with $RESOURCE"
    break
  fi
done

if [ "$AUTH_EXISTS" = false ]; then
  echo "❌ The ServerAuthorization resource 'backend-server-auth' is missing."
  echo "Available API resources that might be ServerAuthorization:"
  kubectl api-resources | grep -i "server\|author"
  exit 1
fi

# Check 6: Test connectivity from frontend to backend
echo "Testing authorized service connectivity..."
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

# Install curl if needed
kubectl exec -n secure-apps $FRONTEND_POD -c nginx -- which curl &>/dev/null || kubectl exec -n secure-apps $FRONTEND_POD -c nginx -- apk add --no-cache curl &>/dev/null

# Test connectivity
HTTP_STATUS=$(kubectl exec -n secure-apps $FRONTEND_POD -c nginx -- curl -s -o /dev/null -w "%{http_code}" http://backend.secure-apps.svc.cluster.local --max-time 10 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Great! You've successfully implemented and tested mTLS and security policies in your Linkerd mesh."
  exit 0
else
  echo "❌ The frontend pod cannot access the backend service. Please check your network policies and service configuration."
  exit 1
fi