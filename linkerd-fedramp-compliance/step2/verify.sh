#!/bin/bash

# Check if policy controller is installed
if ! kubectl get deployments -n linkerd linkerd-policy-controller &>/dev/null; then
  echo "Linkerd policy controller is not installed. Please complete the step."
  exit 1
fi

# Check if service accounts exist (we're not deploying actual apps)
if ! kubectl get serviceaccount frontend -n secure-apps &>/dev/null || ! kubectl get serviceaccount backend -n secure-apps &>/dev/null || ! kubectl get serviceaccount database -n secure-apps &>/dev/null; then
  echo "Service accounts are not created. Please complete the step."
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

# Success
echo "Step 2 completed successfully! You've correctly configured Linkerd's authentication controls."
exit 0