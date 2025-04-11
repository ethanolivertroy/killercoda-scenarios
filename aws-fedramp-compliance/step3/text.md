# Generating FedRAMP Compliance Reports

In this step, we will:
1. Generate a comprehensive FedRAMP compliance report
2. Understand remediation strategies for non-compliant resources
3. Learn about continuous compliance monitoring

## Generating Compliance Reports

Let's generate a comprehensive compliance report based on our findings:

```
# Generate FedRAMP compliance report
mkdir -p ~/fedramp-evidence
cat /root/compliance-results.json | jq > ~/fedramp-evidence/compliance-findings.json

# Generate a summary report in markdown format
cat << EOF > ~/fedramp-evidence/compliance-summary.md
# AWS FedRAMP Compliance Assessment Summary

## Overview
This report summarizes the FedRAMP compliance status of the assessed AWS environment.

## Non-Compliant Resources

### S3 Buckets
- **non-compliant-public-bucket**
  - **Finding**: Public access enabled
  - **Control**: AC-3 (Access Enforcement), AC-6 (Least Privilege)
  - **Remediation**: Remove public access using \`s3api put-bucket-acl\` with private ACL
  - **Finding**: No encryption configured
  - **Control**: SC-13 (Cryptographic Protection)
  - **Remediation**: Enable default encryption using \`s3api put-bucket-encryption\`

### IAM Policies
- **OverlyPermissivePolicy (attached to admin-user)**
  - **Finding**: Allows all actions (*) on all resources
  - **Control**: AC-6 (Least Privilege)
  - **Remediation**: Modify policy to restrict permissions to only what is needed

## Compliant Resources

### S3 Buckets
- **compliant-private-bucket**
  - **Status**: Compliant with AC-3, AC-6, SC-13
  - **Implemented Controls**: Private access, default encryption

### IAM Policies
- **LeastPrivilegePolicy (attached to fedramp-auditor)**
  - **Status**: Compliant with AC-6
  - **Implemented Controls**: Specific permissions to specific resources

### CloudTrail Logs
- **cloudtrail-logs bucket**
  - **Status**: Compliant with AU-2, AU-9
  - **Implemented Controls**: API activity logs stored in S3

## FedRAMP Control Coverage
- **AC-2 (Account Management)**: Partially compliant
- **AC-3 (Access Enforcement)**: Partially compliant
- **AC-6 (Least Privilege)**: Partially compliant
- **AU-2 (Audit Events)**: Compliant
- **AU-9 (Protection of Audit Information)**: Compliant
- **SC-13 (Cryptographic Protection)**: Partially compliant

## Remediation Plan
1. Remove public access from non-compliant buckets
2. Enable encryption on all storage resources
3. Review and restrict overly permissive IAM policies
4. Implement resource tagging for inventory management (CM-8)
5. Configure network controls for boundary protection (SC-7)
EOF

# Copy the FedRAMP controls reference for documentation
cp /root/compliance-checklist.md ~/fedramp-evidence/

# List generated evidence
ls -la ~/fedramp-evidence/
```{{exec}}

Let's examine the summary report:

```
cat ~/fedramp-evidence/compliance-summary.md
```{{exec}}

## Remediation Strategies

Now, let's apply some remediation strategies to fix non-compliant resources:

```
# 1. Remediate S3 public bucket issue
echo "Remediating public S3 bucket..."
aws --endpoint-url=http://localhost:4566 s3api put-bucket-acl --bucket non-compliant-public-bucket --acl private

# Verify fix
aws --endpoint-url=http://localhost:4566 s3api get-bucket-acl --bucket non-compliant-public-bucket | grep "AllUsers" || echo "Public access removed successfully"

# 2. Enable encryption on non-compliant bucket
echo -e "\nEnabling encryption on non-compliant bucket..."
aws --endpoint-url=http://localhost:4566 s3api put-bucket-encryption \
    --bucket non-compliant-public-bucket \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

# Verify fix
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket non-compliant-public-bucket

# 3. Fix overly permissive IAM policy
echo -e "\nRemediating overly permissive IAM policy..."

# Create more restrictive policy
cat <<EOF > /tmp/restricted-admin-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:ListUsers"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Update policy (using hardcoded ARN since the query might not work in Killercoda)
aws --endpoint-url=http://localhost:4566 iam create-policy-version \
    --policy-arn arn:aws:iam::000000000000:policy/OverlyPermissivePolicy \
    --policy-document file:///tmp/restricted-admin-policy.json \
    --set-as-default

# Verify fix
aws --endpoint-url=http://localhost:4566 iam get-policy-version \
    --policy-arn arn:aws:iam::000000000000:policy/OverlyPermissivePolicy \
    --version-id v2
```{{exec}}

## Continuous Compliance Monitoring

For ongoing FedRAMP compliance in real AWS environments, you would implement:

1. **AWS Config** - For continuous resource configuration assessment
2. **AWS Security Hub** - For centralized security findings
3. **Amazon GuardDuty** - For threat detection
4. **AWS CloudTrail** - For API activity logging
5. **Amazon CloudWatch** - For metric collection and alerting

With LocalStack, you can simulate several of these services to practice your compliance monitoring:

```
# Set up a recurring compliance check script
cat << EOF > /root/continuous-compliance.sh
#!/bin/bash

echo "Running continuous compliance check at \$(date)"

# Check S3 Buckets for public access
echo "Checking S3 buckets for public access..."
aws --endpoint-url=http://localhost:4566 s3api list-buckets --query 'Buckets[*].Name' --output text | tr '\t' '\n' | while read bucket; do
  if aws --endpoint-url=http://localhost:4566 s3api get-bucket-acl --bucket \$bucket | grep -q "AllUsers"; then
    echo "VIOLATION: Bucket \$bucket has public access"
  else
    echo "COMPLIANT: Bucket \$bucket has no public access"
  fi
done

# Check S3 Buckets for encryption
echo -e "\nChecking S3 buckets for encryption..."
aws --endpoint-url=http://localhost:4566 s3api list-buckets --query 'Buckets[*].Name' --output text | tr '\t' '\n' | while read bucket; do
  if aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket \$bucket &>/dev/null; then
    echo "COMPLIANT: Bucket \$bucket has encryption enabled"
  else
    echo "VIOLATION: Bucket \$bucket has no encryption"
  fi
done

# Check IAM policies for least privilege
echo -e "\nChecking IAM policies for least privilege..."
aws --endpoint-url=http://localhost:4566 iam list-policies --scope Local --query 'Policies[*].[PolicyName, Arn]' --output text | while read line; do
  policy_name=\$(echo \$line | cut -d' ' -f1)
  policy_arn=\$(echo \$line | cut -d' ' -f2)
  
  if aws --endpoint-url=http://localhost:4566 iam get-policy-version --policy-arn \$policy_arn --version-id v1 | grep -q '"Action": "\*"'; then
    echo "VIOLATION: Policy \$policy_name has overly permissive actions"
  else
    echo "COMPLIANT: Policy \$policy_name follows least privilege"
  fi
done

# Output to compliance log
echo -e "\nCompliance check completed. Run at \$(date)" 
EOF

chmod +x /root/continuous-compliance.sh

# Run the compliance check
/root/continuous-compliance.sh
```{{exec}}

In a production AWS environment, you would schedule this to run regularly using CloudWatch Events.

## Conclusion

You have successfully:
1. Generated comprehensive FedRAMP compliance reports
2. Applied remediation strategies to fix non-compliant resources
3. Set up a continuous compliance monitoring script

These skills are essential for maintaining FedRAMP compliance in real AWS environments. While LocalStack provides a simplified simulation, the concepts and approaches we've covered apply directly to actual AWS deployments.

Remember that FedRAMP compliance is an ongoing process, not a one-time activity. Continuous monitoring, regular assessments, and prompt remediation of issues are all crucial components of maintaining compliance.