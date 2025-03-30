#!/bin/bash

# Check if the user has created the network policy
if kubectl get networkpolicy frontend-to-backend-only -n fedramp-demo &>/dev/null; then
  # Check if the audit script exists and is executable
  if [[ -x /root/fedramp-k8s-audit.sh ]]; then
    # Check if the findings report exists
    if [[ -f /root/fedramp-findings.md ]]; then
      echo "Great! You've successfully completed the FedRAMP security audit."
      exit 0
    else
      echo "You need to generate the findings report."
      exit 1
    fi
  else
    echo "You need to create the audit script as described in the task."
    exit 1
  fi
else
  echo "You need to create the network policy as described in the task."
  exit 1
fi