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

Let's start by running an automated compliance assessment using our audit tool:

```
# Step 1: Run the automated FedRAMP compliance audit tool
bash /root/aws-audit-tool.sh
```{{exec}}

This script performs the following checks:
1. Connects to LocalStack AWS environment
2. Scans all S3 buckets for public access and encryption settings
3. Evaluates IAM policies for least privilege violations
4. Verifies CloudTrail logs for audit capabilities
5. Maps all findings to specific FedRAMP controls
6. Generates a JSON report with detailed results

## Analyzing S3 Bucket Compliance

Let's take a closer look at our S3 bucket configurations:

```
# Step 2: Begin S3 bucket compliance checks
echo "Checking S3 bucket configurations..."
```{{exec}}

First, let's check for public access on our buckets. FedRAMP controls AC-3 (Access Enforcement) and AC-6 (Least Privilege) require restricting public access:

```
# Step 3: Check non-compliant bucket for public access (AC-3, AC-6)
echo "Checking non-compliant bucket for public access:"
aws s3api get-bucket-acl --bucket non-compliant-public-bucket | grep "AllUsers"
```{{exec}}

```
# Step 4: Check compliant bucket for public access (AC-3, AC-6)
echo "Checking compliant bucket for public access:"
aws s3api get-bucket-acl --bucket compliant-private-bucket | grep "AllUsers" || echo "No public access found (compliant)"
```{{exec}}

Now let's check for encryption. FedRAMP control SC-13 (Cryptographic Protection) requires proper encryption of data at rest:

```
# Step 5: Check compliant bucket for encryption (SC-13)
echo "Checking compliant bucket for encryption:"
aws s3api get-bucket-encryption --bucket compliant-private-bucket
```{{exec}}

```
# Step 6: Check non-compliant bucket for encryption (SC-13)
echo "Checking non-compliant bucket for encryption:"
aws s3api get-bucket-encryption --bucket non-compliant-public-bucket 2>/dev/null || echo "No encryption configured (non-compliant)"
```{{exec}}

## Analyzing IAM Compliance

Now let's analyze our IAM configurations:

```
# Step 7: Begin IAM compliance assessment
echo "Checking IAM configurations for FedRAMP compliance..."
```{{exec}}

Now let's analyze the policies attached to our users. FedRAMP control AC-6 (Least Privilege) requires granting only the permissions needed to perform job functions:

```
# Step 8: Check admin user's policies (AC-6: Least Privilege)
echo "Examining admin-user policies:"
aws iam list-attached-user-policies --user-name admin-user
```{{exec}}

```
# Step 9: View the admin policy details to check for overly permissive rights
echo "Viewing admin policy details:"
aws iam get-policy-version \
  --policy-arn arn:aws:iam::000000000000:policy/OverlyPermissivePolicy \
  --version-id v1
```{{exec}}

Next, let's examine the auditor user's policy, which should follow the principle of least privilege:

```
# Step 10: Check auditor user's policies (AC-6: Least Privilege)
echo "Examining fedramp-auditor policies:"
aws iam list-attached-user-policies --user-name fedramp-auditor
```{{exec}}

```
# Step 11: View the auditor policy details to verify least privilege
echo "Viewing auditor policy details:"
aws iam get-policy-version \
  --policy-arn arn:aws:iam::000000000000:policy/LeastPrivilegePolicy \
  --version-id v1
```{{exec}}

## Analyzing CloudTrail Compliance

Let's examine our CloudTrail configuration for audit compliance:

```
# Step 12: Begin CloudTrail audit compliance assessment
echo "Checking CloudTrail implementation for FedRAMP compliance..."
```{{exec}}

FedRAMP control AU-2 (Audit Events) requires comprehensive logging of system events. Let's verify that our CloudTrail logs are correctly stored:

```
# Step 13: Check CloudTrail logs location and structure (AU-2)
echo "Verifying CloudTrail log files:"
aws s3 ls s3://cloudtrail-logs/ --recursive
```{{exec}}

Let's also examine the content of a sample CloudTrail log to ensure it contains the required information:

```
# Step 14: Review a sample CloudTrail log entry (AU-2, AU-9)
echo "Viewing sample CloudTrail log content:"
aws s3 cp s3://cloudtrail-logs/AWSLogs/000000000000/CloudTrail/us-east-1/$(date +"%Y/%m/%d")/sample-trail.json - | jq .
```{{exec}}

The sample log demonstrates how CloudTrail would record API calls in a production environment, capturing details like:
- Who performed the action (userIdentity)
- What action was taken (eventName)
- When it occurred (eventTime)
- Where the action was directed (resources)
- Source IP and user agent information
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
| CloudTrail logs | AU-2 | Compliant | Logs stored in S3 bucket |
| CloudTrail logs | AU-9 | Compliant | Stored in a dedicated bucket |

In the next step, we'll generate comprehensive compliance reports and discuss remediation strategies for the issues we've identified.