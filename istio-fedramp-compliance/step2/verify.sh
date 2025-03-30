#!/bin/bash

# Check that sample microservices are deployed
if kubectl get deployment -n secure-apps frontend &>/dev/null && kubectl get deployment -n secure-apps backend &>/dev/null; then
  # Check that service-specific PeerAuthentication policies exist
  if kubectl get peerauthentication -n secure-apps frontend-mtls &>/dev/null && kubectl get peerauthentication -n secure-apps backend-mtls &>/dev/null; then
    # Check that RequestAuthentication for JWT is configured
    if kubectl get requestauthentication -n secure-apps jwt-authentication &>/dev/null; then
      # Check that AuthorizationPolicy for JWT is configured
      if kubectl get authorizationpolicy -n secure-apps require-jwt &>/dev/null; then
        echo "Great! You've successfully configured mTLS and JWT authentication controls."
        exit 0
      fi
    fi
  fi
fi

echo "Authentication controls are not completely configured. Please complete all tasks."
exit 1