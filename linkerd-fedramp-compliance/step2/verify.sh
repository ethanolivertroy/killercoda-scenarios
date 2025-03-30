#!/bin/bash

# Check that the secure-apps namespace exists and is annotated for Linkerd
if kubectl get namespace secure-apps &>/dev/null && kubectl get namespace secure-apps -o jsonpath='{.metadata.annotations.linkerd\.io/inject}' | grep -q enabled; then
  # Check that the services are deployed
  if kubectl get deployment frontend -n secure-apps &>/dev/null && kubectl get deployment backend -n secure-apps &>/dev/null; then
    # Check that the authorization policy exists
    if kubectl get serverauthorization backend-server-auth -n secure-apps &>/dev/null; then
      # Check that the HTTP route exists
      if kubectl get httproute backend-route -n secure-apps &>/dev/null; then
        echo "Great! You've successfully implemented and tested mTLS and security policies in your Linkerd mesh."
        exit 0
      fi
    fi
  fi
fi

echo "The security policies are not completely configured. Please complete all tasks."
exit 1