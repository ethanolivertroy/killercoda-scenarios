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
# Create a public S3 bucket (non-compliant)
aws s3 mb s3://non-compliant-public-bucket
aws s3api put-bucket-acl --bucket non-compliant-public-bucket --acl public-read

# Create a private S3 bucket with encryption (compliant)
aws s3 mb s3://compliant-private-bucket
aws s3api put-bucket-encryption \
    --bucket compliant-private-bucket \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
```{{exec}}

Next, let's create some IAM resources:

```
# Create IAM users with varying permission policies
aws iam create-user --user-name fedramp-auditor
aws iam create-user --user-name admin-user

# Create an IAM policy that follows principle of least privilege (compliant)
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

aws iam create-policy \
    --policy-name LeastPrivilegePolicy \
    --policy-document file:///tmp/least-privilege-policy.json

# Create an overly permissive policy (non-compliant)
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

aws iam create-policy \
    --policy-name OverlyPermissivePolicy \
    --policy-document file:///tmp/overly-permissive-policy.json

# Attach policies to users
# Get the policy ARNs
aws iam list-policies --scope Local

# Attach policies directly using the ARN
aws iam attach-user-policy \
    --user-name fedramp-auditor \
    --policy-arn arn:aws:iam::000000000000:policy/LeastPrivilegePolicy

aws iam attach-user-policy \
    --user-name admin-user \
    --policy-arn arn:aws:iam::000000000000:policy/OverlyPermissivePolicy
```{{exec}}

Let's set up a logging bucket (note: full CloudTrail is not available in LocalStack Community Edition):

```
# Create a logging bucket to simulate CloudTrail logs
aws s3 mb s3://cloudtrail-logs

# Create a simple log file to simulate CloudTrail logs
echo '{
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
      "eventTime": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
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
}' > /tmp/cloudtrail-sample.json

# Upload the sample log file to the bucket
aws s3 cp /tmp/cloudtrail-sample.json s3://cloudtrail-logs/AWSLogs/000000000000/CloudTrail/us-east-1/$(date +"%Y/%m/%d")/sample-trail.json
```{{exec}}

## Verifying Resource Deployment

Let's verify that our resources have been created:

```
# List S3 buckets
echo "S3 Buckets:"
aws s3 ls

# List IAM users
echo -e "\nIAM Users:"
aws iam list-users

# List IAM policies
echo -e "\nIAM Policies:"
aws iam list-policies --scope Local

# Check CloudTrail logs bucket
echo -e "\nCloudTrail Logs:"
aws s3 ls s3://cloudtrail-logs/ --recursive
```{{exec}}

Now that we have deployed our sample AWS resources, we have a mix of compliant and non-compliant configurations that we can evaluate against FedRAMP requirements. In the next step, we'll perform compliance assessments on these resources.