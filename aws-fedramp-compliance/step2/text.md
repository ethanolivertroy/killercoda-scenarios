# Evaluating AWS Resources Against FedRAMP Controls

In this step, we will:
1. Understand key FedRAMP controls applicable to AWS resources
2. Run compliance checks against our deployed resources
3. Analyze compliance findings and identify gaps

## Understanding FedRAMP Controls for AWS

FedRAMP controls are based on NIST 800-53 and cover a wide range of security requirements. For AWS environments, some key controls include:

| Control Family | Control ID | Description | AWS Service Relevance |
|----------------|------------|-------------|------------------------|
| Access Control | AC-2 | Account Management | IAM users, roles, policies |
| Access Control | AC-3 | Access Enforcement | IAM policies, S3 bucket policies |
| Access Control | AC-6 | Least Privilege | IAM permission boundaries |
| Audit & Accountability | AU-2 | Audit Events | CloudTrail configuration |
| Audit & Accountability | AU-9 | Protection of Audit Information | CloudTrail log encryption, S3 bucket security |
| Configuration Management | CM-7 | Least Functionality | Security Groups, NACLs |
| Configuration Management | CM-8 | Information System Component Inventory | AWS Config |
| System & Communications Protection | SC-7 | Boundary Protection | VPC design, subnets, gateways |
| System & Communications Protection | SC-13 | Cryptographic Protection | KMS, S3 encryption, EBS encryption |

## Running FedRAMP Compliance Checks

Let's use our AWS audit tool to run compliance checks against our deployed resources. This tool evaluates resources against common FedRAMP controls:

```
# Run the audit tool
bash /root/aws-audit-tool.sh
```{{exec}}

This script will:
1. Connect to LocalStack
2. Scan resources for compliance issues
3. Map findings to relevant FedRAMP controls
4. Generate a report of compliance status

## Analyzing S3 Bucket Compliance

Let's take a closer look at our S3 bucket configurations:

```
# Evaluate S3 bucket compliance with FedRAMP controls
echo "Checking S3 bucket configurations..."

# Check for public access
echo -e "\nPublic Access Check (AC-3, AC-6):"
aws --endpoint-url=http://localhost:4566 s3api get-bucket-acl --bucket non-compliant-public-bucket | grep "AllUsers"
aws --endpoint-url=http://localhost:4566 s3api get-bucket-acl --bucket compliant-private-bucket | grep "AllUsers" || echo "No public access found (compliant)"

# Check for encryption
echo -e "\nEncryption Check (SC-13):"
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket compliant-private-bucket || echo "Failed to get encryption configuration"
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket non-compliant-public-bucket 2>/dev/null || echo "No encryption configured (non-compliant)"
```{{exec}}

## Analyzing IAM Compliance

Now let's analyze our IAM configurations:

```
# Evaluate IAM compliance with FedRAMP controls
echo -e "\nChecking IAM configurations..."

# Check user policies (AC-6: Least Privilege)
echo -e "\nIAM Policy Check (AC-6):"
echo "Policy for admin-user:"
aws --endpoint-url=http://localhost:4566 iam list-attached-user-policies --user-name admin-user
ADMIN_POLICY_ARN=$(aws --endpoint-url=http://localhost:4566 iam list-attached-user-policies --user-name admin-user --query 'AttachedPolicies[0].PolicyArn' --output text)
aws --endpoint-url=http://localhost:4566 iam get-policy-version --policy-arn $ADMIN_POLICY_ARN --version-id v1

echo -e "\nPolicy for fedramp-auditor:"
aws --endpoint-url=http://localhost:4566 iam list-attached-user-policies --user-name fedramp-auditor
AUDITOR_POLICY_ARN=$(aws --endpoint-url=http://localhost:4566 iam list-attached-user-policies --user-name fedramp-auditor --query 'AttachedPolicies[0].PolicyArn' --output text)
aws --endpoint-url=http://localhost:4566 iam get-policy-version --policy-arn $AUDITOR_POLICY_ARN --version-id v1
```{{exec}}

## Analyzing CloudTrail Compliance

Let's examine our CloudTrail configuration for audit compliance:

```
# Evaluate CloudTrail compliance with FedRAMP controls
echo -e "\nChecking CloudTrail configurations..."

# Check trail configuration (AU-2: Audit Events)
echo -e "\nCloudTrail Configuration Check (AU-2):"
aws --endpoint-url=http://localhost:4566 cloudtrail describe-trails

# Check if logging is enabled
echo -e "\nCloudTrail Logging Status Check (AU-2):"
aws --endpoint-url=http://localhost:4566 cloudtrail get-trail-status --name management-events-trail
```{{exec}}

## Compliance Analysis Summary

Let's summarize our findings:

| Resource | FedRAMP Control | Status | Finding |
|----------|-----------------|--------|---------|
| non-compliant-public-bucket | AC-3, AC-6 | Non-Compliant | Public read access enabled |
| non-compliant-public-bucket | SC-13 | Non-Compliant | No encryption configured |
| compliant-private-bucket | AC-3, AC-6 | Compliant | No public access |
| compliant-private-bucket | SC-13 | Compliant | Encryption configured |
| admin-user IAM policy | AC-6 | Non-Compliant | Overly permissive (* actions) |
| fedramp-auditor IAM policy | AC-6 | Compliant | Adheres to least privilege |
| CloudTrail | AU-2 | Compliant | Logging enabled for management events |
| CloudTrail logs | AU-9 | Compliant | Stored in a bucket |

In the next step, we'll generate comprehensive compliance reports and discuss remediation strategies for the issues we've identified.