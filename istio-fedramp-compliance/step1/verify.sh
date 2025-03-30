#!/bin/bash

# Check that Istio is installed
if kubectl get namespace istio-system &>/dev/null; then
  if kubectl get pods -n istio-system | grep -q istiod; then
    # Check that strict mTLS is configured
    if kubectl get peerauthentication -n istio-system | grep -q default; then
      # Check namespace created
      if kubectl get namespace secure-apps &>/dev/null; then
        # Check that at least one monitoring component is installed
        if kubectl get pods -n istio-system | grep -q -E 'prometheus|grafana|kiali'; then
          echo "Great! You've successfully set up a secure Istio service mesh with mTLS and monitoring."
          exit 0
        else
          echo "Please install the monitoring components (Prometheus, Grafana, or Kiali)."
          exit 1
        fi
      fi
    fi
  fi
fi

echo "The secure Istio service mesh is not completely configured. Please complete all tasks."
exit 1