#!/bin/bash

# Check that Istio is installed
if kubectl get namespace istio-system &>/dev/null; then
  if kubectl get pods -n istio-system | grep -q istiod; then
    # Check that strict mTLS is configured
    if kubectl get peerauthentication -n istio-system | grep -q default; then
      # Check namespace created
      if kubectl get namespace secure-apps &>/dev/null; then
        echo "Great! You've successfully set up a secure Istio service mesh with mTLS configuration."
        exit 0
      fi
    fi
  fi
fi

echo "The secure Istio service mesh is not completely configured. Please complete all tasks."
exit 1