#!/bin/bash

# Check that Linkerd is installed with basic components
if kubectl get namespace linkerd &>/dev/null; then
  if kubectl get deployment linkerd-identity -n linkerd &>/dev/null; then
    # Check that key components are running
    IDENTITY_READY=$(kubectl get deployment linkerd-identity -n linkerd -o jsonpath='{.status.readyReplicas}')
    PROXY_INJECTOR_READY=$(kubectl get deployment linkerd-proxy-injector -n linkerd -o jsonpath='{.status.readyReplicas}')
    
    if [ "$IDENTITY_READY" -gt 0 ] && [ "$PROXY_INJECTOR_READY" -gt 0 ]; then
      echo "Great! You've successfully installed a secure Linkerd service mesh with FedRAMP-compliant configuration."
      exit 0
    fi
  fi
fi

echo "The Linkerd service mesh is not completely configured. Please complete all tasks."
exit 1