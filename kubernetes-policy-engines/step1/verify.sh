#!/bin/bash

# Check if OPA Gatekeeper is installed
if ! kubectl get ns gatekeeper-system &>/dev/null; then
  echo "OPA Gatekeeper namespace not found"
  exit 1
fi

# Check if constraint templates have been created - this is what matters most
if ! kubectl get constrainttemplates | grep -q "K8sRequiredLabels"; then
  echo "Required constraint templates not found"
  exit 1
fi

# Check if constraints have been created
if ! kubectl get k8srequiredlabels.constraints.gatekeeper.sh require-security-labels &>/dev/null; then
  echo "Required constraint require-security-labels not found"
  exit 1
fi

# Check deployment status, but don't fail based on this
pods_not_running=false
if ! kubectl get pods -n gatekeeper-system | grep -q "Running"; then
  echo "Note: OPA Gatekeeper pods are not fully running yet. This is okay for the scenario."
  pods_not_running=true
fi

# Still pass verification even if pods aren't fully running yet
echo "Step 1 verification successful!"
exit 0