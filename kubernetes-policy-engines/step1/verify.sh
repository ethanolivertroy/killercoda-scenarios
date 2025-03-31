#!/bin/bash

# Check if OPA Gatekeeper is installed
if ! kubectl get ns gatekeeper-system &>/dev/null; then
  echo "OPA Gatekeeper namespace not found"
  exit 1
fi

# Check if OPA Gatekeeper pods are running
if ! kubectl get pods -n gatekeeper-system | grep -q "Running"; then
  echo "OPA Gatekeeper pods are not running"
  exit 1
fi

# Check if constraint templates have been created
if ! kubectl get constrainttemplates | grep -q "K8sRequiredLabels"; then
  echo "Required constraint templates not found"
  exit 1
fi

# Check if constraints have been created
if ! kubectl get k8srequiredlabels.constraints.gatekeeper.sh require-security-labels &>/dev/null; then
  echo "Required constraint require-security-labels not found"
  exit 1
fi

echo "Step 1 verification successful!"
exit 0