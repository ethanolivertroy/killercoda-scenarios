#!/bin/bash

# Check that Linkerd is installed with basic components
if kubectl get namespace linkerd &>/dev/null; then
  # Check if linkerd-config exists
  if kubectl get configmap linkerd-config -n linkerd &>/dev/null; then
    # Check that the required deployments exist
    if kubectl get deployment linkerd-identity -n linkerd &>/dev/null && \
       kubectl get deployment linkerd-destination -n linkerd &>/dev/null && \
       kubectl get deployment linkerd-proxy-injector -n linkerd &>/dev/null; then
      
      # Check that at least one pod for each deployment is running
      IDENTITY_PODS=$(kubectl get pods -n linkerd -l linkerd.io/control-plane-component=identity -o jsonpath='{.items[*].status.phase}' | grep -c "Running" || echo "0")
      DESTINATION_PODS=$(kubectl get pods -n linkerd -l linkerd.io/control-plane-component=destination -o jsonpath='{.items[*].status.phase}' | grep -c "Running" || echo "0")
      PROXY_INJECTOR_PODS=$(kubectl get pods -n linkerd -l linkerd.io/control-plane-component=proxy-injector -o jsonpath='{.items[*].status.phase}' | grep -c "Running" || echo "0")
      
      if [ "$IDENTITY_PODS" -gt 0 ] && [ "$DESTINATION_PODS" -gt 0 ] && [ "$PROXY_INJECTOR_PODS" -gt 0 ]; then
        # Also check for Viz extension, but don't fail if it's not there yet
        if kubectl get namespace linkerd-viz &>/dev/null; then
          VIZ_PODS=$(kubectl get pods -n linkerd-viz -o jsonpath='{.items[*].status.phase}' | grep -c "Running" || echo "0")
          if [ "$VIZ_PODS" -gt 0 ]; then
            echo "Great! You've successfully installed a secure Linkerd service mesh with the Viz extension."
          else
            echo "Great! You've successfully installed a secure Linkerd service mesh, but Viz extension pods are not running yet."
          fi
        else
          echo "Great! You've successfully installed a secure Linkerd service mesh. Don't forget to install the Viz extension."
        fi
        exit 0
      fi
    fi
  fi
fi

echo "The Linkerd service mesh is not completely configured. Please complete all tasks."
exit 1