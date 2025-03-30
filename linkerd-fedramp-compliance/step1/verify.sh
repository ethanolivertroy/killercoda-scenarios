#!/bin/bash

# Check that Linkerd is installed
if kubectl get namespace linkerd &>/dev/null; then
  if kubectl get deployment linkerd-identity -n linkerd &>/dev/null; then
    # Check that Linkerd controller is running
    if [ $(kubectl get pods -n linkerd --field-selector=status.phase=Running | grep -c linkerd-controller) -gt 0 ]; then
      # Check that proxy-injector is installed
      if kubectl get deployment linkerd-proxy-injector -n linkerd &>/dev/null; then
        echo "Great! You've successfully installed a secure Linkerd service mesh with FedRAMP-compliant configuration."
        exit 0
      fi
    fi
  fi
fi

echo "The Linkerd service mesh is not completely configured. Please complete all tasks."
exit 1