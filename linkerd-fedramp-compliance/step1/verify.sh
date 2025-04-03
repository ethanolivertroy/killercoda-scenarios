#!/bin/bash

# Check if Linkerd is installed
if ! kubectl get namespace linkerd &>/dev/null; then
  echo "Linkerd is not installed. Please complete the step."
  exit 1
fi

# Check if secure-apps namespace exists with correct annotation
if ! kubectl get namespace secure-apps -o jsonpath='{.metadata.annotations.linkerd\.io/inject}' | grep -q "enabled"; then
  echo "secure-apps namespace is not properly configured with Linkerd injection."
  exit 1
fi

# Check if default network policy exists
if ! kubectl get networkpolicy default-deny -n secure-apps &>/dev/null; then
  echo "Default deny network policy is not configured in secure-apps namespace."
  exit 1
fi

# Success
echo "Step 1 completed successfully!"
exit 0