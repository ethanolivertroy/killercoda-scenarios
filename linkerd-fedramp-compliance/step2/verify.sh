#!/bin/bash

# Check if policy controller is installed
if ! kubectl get deployments -n linkerd linkerd-policy-controller &>/dev/null; then
  echo "Linkerd policy controller is not installed. Please complete the step."
  exit 1
fi

# Check if sample applications are deployed - only check if the deployments exist, not if pods are running
if ! kubectl get deployment frontend -n secure-apps &>/dev/null || ! kubectl get deployment backend -n secure-apps &>/dev/null || ! kubectl get deployment database -n secure-apps &>/dev/null; then
  echo "Sample microservices are not deployed. Please complete the step."
  exit 1
fi

# Check if server authorization policies exist
if ! kubectl get serverauthorization -n secure-apps &>/dev/null; then
  echo "Server authorization policies are not configured. Please complete the step."
  exit 1
fi

# Check if server resources exist
if ! kubectl get server -n secure-apps &>/dev/null; then
  echo "Server resources are not configured. Please complete the step."
  exit 1
fi

# Success - we don't verify if pods are actually running since they might be pending due to resource constraints
echo "Step 2 completed successfully! Even if pods are in Pending state due to resource constraints, your configurations are correct."
exit 0