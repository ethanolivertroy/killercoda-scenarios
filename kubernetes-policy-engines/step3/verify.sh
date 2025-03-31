#!/bin/bash

# Check if the policy-audit-tool.sh is executable
if [ ! -x /root/policy-audit-tool.sh ]; then
  echo "policy-audit-tool.sh is not executable"
  exit 1
fi

# Check if the evidence directory exists
if [ ! -d ~/fedramp-evidence/policy-enforcement ]; then
  echo "Evidence directory not created"
  exit 1
fi

# Check if summary report has been generated
if [ ! -f ~/fedramp-evidence/policy-enforcement/summary.md ]; then
  echo "Summary report not generated"
  exit 1
fi

# Check if cronjob was created
if ! kubectl get cronjob policy-compliance-audit &>/dev/null; then
  echo "Policy compliance audit cronjob not found"
  exit 1
fi

echo "Step 3 verification successful!"
exit 0