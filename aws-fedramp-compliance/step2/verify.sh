#!/bin/bash

# Check if aws-audit-tool.sh has been run
if [ ! -f /root/compliance-results.json ]; then
  echo "Compliance check results not found. Please run the aws-audit-tool.sh script."
  exit 1
fi

# Check if key resources were evaluated
if ! grep -q "non-compliant-public-bucket" /root/compliance-results.json; then
  echo "Public bucket evaluation not found in results"
  exit 1
fi

if ! grep -q "admin-user" /root/compliance-results.json; then
  echo "IAM user evaluation not found in results"
  exit 1
fi

if ! grep -q "CloudTrail" /root/compliance-results.json; then
  echo "CloudTrail evaluation not found in results"
  exit 1
fi

echo "Step 2 verification successful!"
exit 0