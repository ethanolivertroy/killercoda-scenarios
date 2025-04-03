#!/bin/bash

# Check if network authentication policies exist
if ! kubectl get networkauthentication -n secure-apps &>/dev/null; then
  echo "Network authentication policies are not configured. Please complete the step."
  exit 1
fi

# Check if specific server and http routes exist
if ! kubectl get server backend-server-http -n secure-apps &>/dev/null || ! kubectl get httproute -n secure-apps &>/dev/null; then
  echo "HTTP route resources are not properly configured. Please complete the step."
  exit 1
fi

# Check if pod security standards are applied to the namespace
if ! kubectl get namespace secure-apps -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' | grep -q "restricted"; then
  echo "Pod security standards are not properly configured in secure-apps namespace."
  exit 1
fi

# Check if the FedRAMP report has been generated
if [ ! -f /root/linkerd-fedramp-report.md ]; then
  echo "FedRAMP compliance report has not been generated. Please complete the step."
  exit 1
fi

# Success
echo "Step 3 completed successfully!"
exit 0