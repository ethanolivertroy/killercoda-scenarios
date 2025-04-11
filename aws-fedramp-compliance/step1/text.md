# Setting Up LocalStack and AWS Environment

In this step, we will:
1. Verify LocalStack is running correctly
2. Configure AWS CLI to work with LocalStack
3. Deploy sample AWS resources for compliance evaluation

## Verifying LocalStack

LocalStack should already be running based on our setup script. Let's verify that it's working properly:

```
docker ps | grep localstack
```{{exec}}

You should see the LocalStack container running. Next, let's check that the AWS CLI is properly configured to work with LocalStack:

```
aws s3 ls
```{{exec}}

If LocalStack is running correctly, this command should execute without errors (though it may show no buckets yet).

## Understanding LocalStack and AWS Emulation

LocalStack provides a cloud service emulator that runs in a Docker container on your local machine. It supports a wide range of AWS services including:
- S3
- IAM
- CloudFormation
- Lambda
- CloudWatch
- and many more

This allows us to create and test AWS resources locally without accessing actual AWS resources or incurring any costs. For FedRAMP compliance assessment, this is particularly useful for:

1. Testing security configurations before deployment
2. Evaluating compliance requirements in a controlled environment
3. Training security personnel without risking actual production environments

## Deploying Sample AWS Resources

Now, let's deploy some AWS resources that represent common cloud architecture patterns. We'll use these resources to evaluate compliance with FedRAMP controls.

First, let's create an S3 bucket with various security configurations:

```
# Step 1: Create a non-compliant public S3 bucket
aws s3 mb s3://non-compliant-public-bucket
```{{exec}}

Now let's make this bucket publicly accessible, which violates FedRAMP AC-3 (Access Enforcement):

```
# Step 2: Set bucket ACL to public-read (non-compliant)
aws s3api put-bucket-acl --bucket non-compliant-public-bucket --acl public-read
```{{exec}}

Next, let's create a FedRAMP-compliant S3 bucket as a comparison:

```
# Step 3: Create a private S3 bucket
aws s3 mb s3://compliant-private-bucket
```{{exec}}

Now let's enable encryption on the compliant bucket, which satisfies FedRAMP SC-13 (Cryptographic Protection):

```
# Step 4: Enable default encryption (compliant)
aws s3api put-bucket-encryption \
    --bucket compliant-private-bucket \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
```{{exec}}

Next, let's create some IAM resources:

```
# Step 5: Create an auditor IAM user
aws iam create-user --user-name fedramp-auditor
```{{exec}}

```
# Step 6: Create an administrator IAM user
aws iam create-user --user-name admin-user
```{{exec}}

Now let's create a policy that follows the principle of least privilege (AC-6):

```
# Step 7: Create a least-privilege policy JSON file (compliant)
cat <<EOF > /tmp/least-privilege-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::compliant-private-bucket",
        "arn:aws:s3:::compliant-private-bucket/*"
      ]
    }
  ]
}
EOF
```{{exec}}

```
# Step 8: Create the least-privilege policy in IAM
aws iam create-policy \
    --policy-name LeastPrivilegePolicy \
    --policy-document file:///tmp/least-privilege-policy.json
```{{exec}}

For comparison, let's create a non-compliant policy that violates the principle of least privilege:

```
# Step 9: Create an overly permissive policy JSON file (non-compliant)
cat <<EOF > /tmp/overly-permissive-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
```{{exec}}

```
# Step 10: Create the overly permissive policy in IAM
aws iam create-policy \
    --policy-name OverlyPermissivePolicy \
    --policy-document file:///tmp/overly-permissive-policy.json

# Step 11: List all our IAM policies to verify creation
aws iam list-policies --scope Local
```{{exec}}

Now, let's attach the policies to our users:

```
# Step 12: Attach the least-privilege policy to the auditor (compliant)
aws iam attach-user-policy \
    --user-name fedramp-auditor \
    --policy-arn arn:aws:iam::000000000000:policy/LeastPrivilegePolicy
```{{exec}}

```
# Step 13: Attach the overly permissive policy to the admin (non-compliant)
aws iam attach-user-policy \
    --user-name admin-user \
    --policy-arn arn:aws:iam::000000000000:policy/OverlyPermissivePolicy
```{{exec}}

Let's set up a logging bucket (note: full CloudTrail is not available in LocalStack Community Edition):

```
# Step 14: Create a logging bucket for audit records
aws s3 mb s3://cloudtrail-logs
```{{exec}}

In real AWS, we would use CloudTrail for comprehensive logging, but in LocalStack Community Edition, we'll simulate this with a sample log file:

```
# Step 15: Create a sample CloudTrail log entry
cat <<EOF > /tmp/cloudtrail-sample.json
{
  "Records": [
    {
      "eventVersion": "1.08",
      "userIdentity": {
        "type": "IAMUser",
        "principalId": "EXAMPLE",
        "arn": "arn:aws:iam::000000000000:user/admin-user",
        "accountId": "000000000000",
        "accessKeyId": "EXAMPLE",
        "userName": "admin-user"
      },
      "eventTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "eventSource": "s3.amazonaws.com",
      "eventName": "CreateBucket",
      "awsRegion": "us-east-1",
      "sourceIPAddress": "127.0.0.1",
      "userAgent": "aws-cli/2.0.0",
      "requestParameters": {
        "bucketName": "non-compliant-public-bucket"
      },
      "responseElements": null,
      "requestID": "EXAMPLE123456789",
      "eventID": "EXAMPLE123456789",
      "readOnly": false,
      "eventType": "AwsApiCall",
      "managementEvent": true,
      "recipientAccountId": "000000000000"
    }
  ]
}
EOF
```{{exec}}

Now let's upload our log file to the bucket in a structure that mimics AWS CloudTrail logs:

```
# Step 16: Upload the log file to the CloudTrail logs bucket
aws s3 cp /tmp/cloudtrail-sample.json s3://cloudtrail-logs/AWSLogs/000000000000/CloudTrail/us-east-1/$(date +"%Y/%m/%d")/sample-trail.json
```{{exec}}

## Verifying Resource Deployment

Let's verify that our resources have been created:

```
# Step 17: List all created S3 buckets
echo "S3 Buckets:"
aws s3 ls
```{{exec}}

```
# Step 18: List all IAM users
echo "IAM Users:"
aws iam list-users
```{{exec}}

```
# Step 19: List all IAM policies
echo "IAM Policies:"
aws iam list-policies --scope Local
```{{exec}}

```
# Step 20: Verify our CloudTrail log files
echo "CloudTrail Logs:"
aws s3 ls s3://cloudtrail-logs/ --recursive
```{{exec}}

Now that we have deployed our sample AWS resources, we have a mix of compliant and non-compliant configurations that we can evaluate against FedRAMP requirements. In the next step, we'll perform compliance assessments on these resources.