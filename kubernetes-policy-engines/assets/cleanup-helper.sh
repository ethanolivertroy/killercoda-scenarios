#!/bin/bash

# Helper script to clean up resources and free memory
# This can be run between steps if you're experiencing resource issues

echo "Performing cleanup to free up resources..."

# Drop caches to free up memory
echo 3 > /proc/sys/vm/drop_caches

# Remove non-essential pods
kubectl delete pod --field-selector=status.phase==Succeeded -A
kubectl delete pod --field-selector=status.phase==Failed -A

# Clean up policy artifacts that might be stuck
echo "Cleaning up policy artifacts..."

# Check if ValidatingAdmissionPolicies exist and clean them up if needed
if kubectl get validatingadmissionpolicies &>/dev/null; then
  echo "Cleaning up ValidatingAdmissionPolicies resources..."
  
  # Delete policy bindings
  for binding in $(kubectl get validatingadmissionpolicybindings -o name 2>/dev/null); do
    kubectl delete $binding 2>/dev/null
  done
  
  # Delete policies
  for policy in $(kubectl get validatingadmissionpolicies -o name 2>/dev/null); do
    kubectl delete $policy 2>/dev/null
  done
fi

# Check if Kyverno is installed and clean up resources if needed
if kubectl get ns kyverno &>/dev/null; then
  echo "Cleaning up Kyverno resources..."
  
  # Clean up policies if desired
  # kubectl delete cpol --all 2>/dev/null
  
  # Scale down kyverno to save resources if it's causing issues
  kubectl scale deployment kyverno -n kyverno --replicas=1 2>/dev/null
fi

echo "Cleanup complete."
echo "If you're experiencing ImagePullBackOff issues:"
echo "1. Make sure you've used the correct image versions in your commands"
echo "2. Wait a few minutes for the system to stabilize"
echo "3. If problems persist, you can restart the scenario"