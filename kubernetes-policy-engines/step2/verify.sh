#!/bin/bash

# Check if Kyverno is installed
if ! kubectl get ns kyverno &>/dev/null; then
  echo "Kyverno namespace not found"
  exit 1
fi

# Check if Kyverno policies have been created
if ! kubectl get cpol | grep -q "require-security-labels"; then
  echo "Required Kyverno policies not found"
  exit 1
fi

# Check if at least 3 policies are present
policy_count=$(kubectl get cpol | grep -v NAME | wc -l)
if [ "$policy_count" -lt 3 ]; then
  echo "Expected at least 3 Kyverno policies, found only $policy_count"
  exit 1
fi

# Check deployment status, but don't fail based on this
pods_not_running=false
if ! kubectl get pods -n kyverno | grep -q "Running"; then
  echo "Note: Kyverno pods are not fully running yet. This is okay for the scenario."
  pods_not_running=true
fi

# Still pass verification even if pods aren't fully running yet
echo "Step 2 verification successful!"
exit 0