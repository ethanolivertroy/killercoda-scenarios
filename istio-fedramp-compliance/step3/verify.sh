#!/bin/bash

# Check that authorization policies exist
if kubectl get authorizationpolicy -n secure-apps default-deny &>/dev/null && kubectl get authorizationpolicy -n secure-apps allow-frontend-to-backend &>/dev/null; then
  # Check that network security controls exist
  if kubectl get gateway -n secure-apps secure-gateway &>/dev/null && kubectl get virtualservice -n secure-apps frontend-vs &>/dev/null; then
    # Check that destination rules exist
    if kubectl get destinationrule -n secure-apps frontend-dr &>/dev/null && kubectl get destinationrule -n secure-apps backend-dr &>/dev/null; then
      # Check that the audit script and report exist
      if [[ -x /root/istio-fedramp-audit.sh ]] && [[ -f /root/istio-fedramp-report.md ]]; then
        echo "Great! You've successfully implemented and audited authorization policies and network security controls."
        exit 0
      fi
    fi
  fi
fi

echo "Authorization policies and network security controls are not completely configured. Please complete all tasks."
exit 1