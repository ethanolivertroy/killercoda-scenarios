#!/bin/bash

# Check if evidence directory exists
if [ ! -d ~/fedramp-evidence ]; then
  echo "FedRAMP evidence directory not found"
  exit 1
fi

# Check if compliance summary was generated
if [ ! -f ~/fedramp-evidence/compliance-summary.md ]; then
  echo "Compliance summary report not found"
  exit 1
fi

# Check if compliance findings JSON file exists
if [ ! -f ~/fedramp-evidence/compliance-findings.json ]; then
  echo "Compliance findings JSON not found"
  exit 1
fi

# Check if continuous compliance script was created
if [ ! -x /root/continuous-compliance.sh ]; then
  echo "Continuous compliance script not found or not executable"
  exit 1
fi

# Check remediation was performed 
# (public access removed from bucket and encryption enabled)
PUBLIC_ACCESS=$(aws --endpoint-url=http://localhost:4566 s3api get-bucket-acl --bucket non-compliant-public-bucket 2>/dev/null | grep -c "AllUsers" || echo "0")
HAS_ENCRYPTION=$(aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket non-compliant-public-bucket 2>/dev/null | grep -c "AES256" || echo "0")

if [ "$PUBLIC_ACCESS" -gt 0 ] || [ "$HAS_ENCRYPTION" -eq 0 ]; then
  echo "Remediation was not completed successfully"
  exit 1
fi

echo "Step 3 verification successful!"
exit 0