#!/bin/bash

# AWS FedRAMP Compliance Audit Tool
echo "Running AWS FedRAMP Compliance Audit Tool..."

# Create results directory
OUTPUT_FILE="/root/compliance-results.json"

# Start building the JSON output
echo '{
  "auditTimestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
  "resourceEvaluations": [' > $OUTPUT_FILE

# Evaluate S3 buckets
echo "Evaluating S3 buckets..."
BUCKETS=$(aws --endpoint-url=http://localhost:4566 s3api list-buckets --query 'Buckets[*].Name' --output text)
FIRST_BUCKET=true

for BUCKET in $BUCKETS; do
  if [ "$FIRST_BUCKET" = true ]; then
    FIRST_BUCKET=false
  else
    echo "," >> $OUTPUT_FILE
  fi
  
  # Get ACL to check for public access
  PUBLIC_ACCESS=$(aws --endpoint-url=http://localhost:4566 s3api get-bucket-acl --bucket $BUCKET | grep -c "AllUsers" || echo "0")
  
  # Check for encryption
  HAS_ENCRYPTION=false
  if aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket $BUCKET &>/dev/null; then
    HAS_ENCRYPTION=true
  fi
  
  # Build findings for this bucket
  cat << EOF >> $OUTPUT_FILE
    {
      "resourceId": "$BUCKET",
      "resourceType": "s3",
      "findings": [
        {
          "controlId": "AC-3",
          "controlName": "Access Enforcement",
          "status": $([ "$PUBLIC_ACCESS" -eq 0 ] && echo '"COMPLIANT"' || echo '"NON_COMPLIANT"'),
          "details": $([ "$PUBLIC_ACCESS" -eq 0 ] && echo '"No public access configured"' || echo '"Public access enabled"')
        },
        {
          "controlId": "AC-6",
          "controlName": "Least Privilege",
          "status": $([ "$PUBLIC_ACCESS" -eq 0 ] && echo '"COMPLIANT"' || echo '"NON_COMPLIANT"'),
          "details": $([ "$PUBLIC_ACCESS" -eq 0 ] && echo '"Access limited to authorized users"' || echo '"Public access violates least privilege"')
        },
        {
          "controlId": "SC-13",
          "controlName": "Cryptographic Protection",
          "status": $([ "$HAS_ENCRYPTION" = true ] && echo '"COMPLIANT"' || echo '"NON_COMPLIANT"'),
          "details": $([ "$HAS_ENCRYPTION" = true ] && echo '"Encryption configured"' || echo '"No encryption configured"')
        }
      ]
    }
EOF
done

# Evaluate IAM users and policies
echo "Evaluating IAM policies..."
if [ "$FIRST_BUCKET" = false ]; then
  echo "," >> $OUTPUT_FILE
fi

USERS=$(aws --endpoint-url=http://localhost:4566 iam list-users --query 'Users[*].UserName' --output text)
FIRST_USER=true

for USER in $USERS; do
  if [ "$FIRST_USER" = true ]; then
    FIRST_USER=false
  else
    echo "," >> $OUTPUT_FILE
  fi
  
  # Get attached policies
  POLICY_ARNS=$(aws --endpoint-url=http://localhost:4566 iam list-attached-user-policies --user-name $USER --query 'AttachedPolicies[*].PolicyArn' --output text)
  
  # Initialize as compliant
  IS_COMPLIANT=true
  POLICY_DETAILS="User has appropriately scoped permissions"
  
  # Check each policy for compliance
  for POLICY_ARN in $POLICY_ARNS; do
    POLICY_DOC=$(aws --endpoint-url=http://localhost:4566 iam get-policy-version --policy-arn $POLICY_ARN --version-id v1)
    
    # Check for overly permissive "*" actions
    if echo "$POLICY_DOC" | grep -q '"Action": "\*"'; then
      IS_COMPLIANT=false
      POLICY_DETAILS="User has overly permissive policy with * actions"
    fi
  done
  
  # Build findings for this user
  cat << EOF >> $OUTPUT_FILE
    {
      "resourceId": "$USER",
      "resourceType": "iam",
      "findings": [
        {
          "controlId": "AC-6",
          "controlName": "Least Privilege",
          "status": $([ "$IS_COMPLIANT" = true ] && echo '"COMPLIANT"' || echo '"NON_COMPLIANT"'),
          "details": "$POLICY_DETAILS"
        }
      ]
    }
EOF
done

# Evaluate CloudTrail logs
echo "Evaluating CloudTrail logs..."
if [ "$FIRST_USER" = false ]; then
  echo "," >> $OUTPUT_FILE
fi

# Check for CloudTrail logs in S3
LOGFILES=$(aws --endpoint-url=http://localhost:4566 s3 ls s3://cloudtrail-logs/ --recursive 2>/dev/null | wc -l)

if [ "$LOGFILES" -eq 0 ]; then
  # No logs exist
  cat << EOF >> $OUTPUT_FILE
    {
      "resourceId": "CloudTrailLogs",
      "resourceType": "s3",
      "findings": [
        {
          "controlId": "AU-2",
          "controlName": "Audit Events",
          "status": "NON_COMPLIANT",
          "details": "No CloudTrail logs found in S3 bucket"
        }
      ]
    }
EOF
else
  # Build findings for CloudTrail logs
  cat << EOF >> $OUTPUT_FILE
    {
      "resourceId": "CloudTrailLogs",
      "resourceType": "s3",
      "findings": [
        {
          "controlId": "AU-2",
          "controlName": "Audit Events",
          "status": "COMPLIANT",
          "details": "CloudTrail logs found in S3 bucket"
        },
        {
          "controlId": "AU-9",
          "controlName": "Protection of Audit Information",
          "status": "COMPLIANT",
          "details": "CloudTrail logs stored in S3 bucket"
        }
      ]
    }
EOF
fi

# Close the JSON structure
echo '
  ]
}' >> $OUTPUT_FILE

echo "Compliance audit completed. Results saved to $OUTPUT_FILE"
echo "Summary of findings:"

# Count compliant and non-compliant findings
COMPLIANT=$(grep -c '"status": "COMPLIANT"' $OUTPUT_FILE)
NON_COMPLIANT=$(grep -c '"status": "NON_COMPLIANT"' $OUTPUT_FILE)

echo "Compliant findings: $COMPLIANT"
echo "Non-compliant findings: $NON_COMPLIANT"

# Display key findings
echo -e "\nKey non-compliant findings:"
grep -A 1 '"status": "NON_COMPLIANT"' $OUTPUT_FILE | grep '"details"' | sort | uniq