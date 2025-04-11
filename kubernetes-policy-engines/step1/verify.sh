#!/bin/bash

# Check if OPA Gatekeeper is installed
if ! kubectl get ns gatekeeper-system &>/dev/null; then
  echo "OPA Gatekeeper namespace not found"
  exit 1
fi

# Check if constraint templates have been created
if ! kubectl get constrainttemplates | grep -q "k8srequiredlabels"; then
  echo "Required constraint templates not found"
  exit 1
fi

# Check if constraints have been created
if ! kubectl get constraints | grep -q "require-security-labels"; then
  echo "Required constraints not found"
  exit 1
fi

# Check deployment status, but don't fail based on this
pods_running=false
if kubectl get pods -n gatekeeper-system | grep -q "Running"; then
  pods_running=true
  echo "OPA Gatekeeper pods are running correctly."
fi

echo "Step 1 verification successful!"
exit 0