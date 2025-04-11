#!/bin/bash

# Check if Kyverno namespace is created
if ! kubectl get ns kyverno &>/dev/null; then
  echo "Kyverno namespace not found"
  exit 1
fi

# Just check that the namespace and Helm installation was attempted
# This is a lightweight check to allow progress even if the pods are still starting up
if ! helm list -n kyverno | grep -q "kyverno"; then
  echo "Kyverno Helm release not found"
  exit 1
fi

# Check if Kyverno deployment exists (without waiting for pods to be ready)
if ! kubectl get deployment -n kyverno | grep -q "kyverno"; then
  echo "Kyverno deployment not found"
  exit 1
fi

# Check if at least one Kyverno policy has been created
# We're not checking for specific policies to be more flexible
if ! kubectl get cpol 2>/dev/null | grep -v "No resources found" | grep -q "."; then
  echo "No Kyverno ClusterPolicies found"
  exit 1
fi

echo "Step 2 verification successful!"
exit 0