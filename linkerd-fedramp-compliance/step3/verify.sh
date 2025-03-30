#!/bin/bash

# Check that the audit script exists and is executable
if [[ -x /root/linkerd-security-audit.sh ]]; then
  # Check that the compliance documentation exists
  if [[ -f /root/linkerd-fedramp-compliance.md ]]; then
    # Check that the audit report was generated
    if [[ -f /root/linkerd-fedramp-audit-report.txt ]]; then
      # Check that the remediation plan exists
      if [[ -f /root/linkerd-security-remediation.md ]]; then
        # Check that the monitoring extension is installed
        if kubectl get namespace linkerd-viz &>/dev/null; then
          echo "Great! You've successfully completed the auditing and compliance documentation for your Linkerd service mesh."
          exit 0
        fi
      fi
    fi
  fi
fi

echo "The auditing and compliance documentation is not complete. Please complete all tasks."
exit 1