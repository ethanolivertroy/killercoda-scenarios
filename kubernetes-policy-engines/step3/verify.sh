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

# Check if at least one policy evidence file exists
# We're more flexible with file names to accommodate our new policy enforcement methods
file_count=$(find ~/fedramp-evidence/policy-enforcement/ -type f | grep -v summary.md | wc -l)
if [ "$file_count" -lt 1 ]; then
  echo "No policy evidence files found"
  exit 1
fi

# Check if cronjob or job was created (more flexible naming)
if ! kubectl get cronjob -o name | grep -q -E 'policy|compliance'; then
  echo "Policy compliance audit job not found"
  exit 1
fi

echo "Step 3 verification successful!"
exit 0