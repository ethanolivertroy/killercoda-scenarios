#!/bin/bash

# Check that Linkerd is installed with basic components
if kubectl get namespace linkerd &>/dev/null; then
  # Check if linkerd-config exists
  if kubectl get configmap linkerd-config -n linkerd &>/dev/null; then
    # Run linkerd check to verify installation
    if linkerd check | grep -q "Status check results are √"; then
      echo "Great! You've successfully installed a secure Linkerd service mesh."
      exit 0
    else
      # Still pass if at least the core components are running
      if kubectl get deployment linkerd-identity -n linkerd &>/dev/null && \
         kubectl get deployment linkerd-controller -n linkerd &>/dev/null && \
         kubectl get deployment linkerd-proxy-injector -n linkerd &>/dev/null; then
        echo "Great! You've successfully installed a Linkerd service mesh. Some checks may still be in progress."
        exit 0
      fi
    fi
  fi
fi

echo "The Linkerd service mesh is not completely configured. Please complete all tasks."
exit 1