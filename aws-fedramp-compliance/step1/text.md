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
aws --endpoint-url=http://localhost:4566 s3 ls
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
aws --endpoint-url=http://localhost:4566 s3 mb s3://non-compliant-public-bucket
aws --endpoint-url=http://localhost:4566 s3api put-bucket-acl --bucket non-compliant-public-bucket --acl public-read

# Create a private S3 bucket with encryption (compliant)
aws --endpoint-url=http://localhost:4566 s3 mb s3://compliant-private-bucket
aws --endpoint-url=http://localhost:4566 s3api put-bucket-encryption \
    --bucket compliant-private-bucket \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
```{{exec}}

Next, let's create some IAM resources:

```
# Create IAM users with varying permission policies
aws --endpoint-url=http://localhost:4566 iam create-user --user-name fedramp-auditor
aws --endpoint-url=http://localhost:4566 iam create-user --user-name admin-user

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

aws --endpoint-url=http://localhost:4566 iam create-policy \
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

aws --endpoint-url=http://localhost:4566 iam create-policy \
    --policy-name OverlyPermissivePolicy \
    --policy-document file:///tmp/overly-permissive-policy.json

# Attach policies to users
LEAST_PRIV_ARN=$(aws --endpoint-url=http://localhost:4566 iam list-policies --query 'Policies[?PolicyName==`LeastPrivilegePolicy`].Arn' --output text)
OVERLY_PERM_ARN=$(aws --endpoint-url=http://localhost:4566 iam list-policies --query 'Policies[?PolicyName==`OverlyPermissivePolicy`].Arn' --output text)

aws --endpoint-url=http://localhost:4566 iam attach-user-policy --user-name fedramp-auditor --policy-arn $LEAST_PRIV_ARN
aws --endpoint-url=http://localhost:4566 iam attach-user-policy --user-name admin-user --policy-arn $OVERLY_PERM_ARN
```{{exec}}

Let's set up CloudTrail for logging and auditing:

```
# Create a CloudTrail trail (this is simplified for LocalStack)
aws --endpoint-url=http://localhost:4566 s3 mb s3://cloudtrail-logs
aws --endpoint-url=http://localhost:4566 cloudtrail create-trail \
    --name management-events-trail \
    --s3-bucket-name cloudtrail-logs \
    --is-multi-region-trail

# Start logging
aws --endpoint-url=http://localhost:4566 cloudtrail start-logging --name management-events-trail
```{{exec}}

## Verifying Resource Deployment

Let's verify that our resources have been created:

```
# List S3 buckets
echo "S3 Buckets:"
aws --endpoint-url=http://localhost:4566 s3 ls

# List IAM users
echo -e "\nIAM Users:"
aws --endpoint-url=http://localhost:4566 iam list-users

# List IAM policies
echo -e "\nIAM Policies:"
aws --endpoint-url=http://localhost:4566 iam list-policies --scope Local

# Check CloudTrail trails
echo -e "\nCloudTrail Trails:"
aws --endpoint-url=http://localhost:4566 cloudtrail list-trails
```{{exec}}

Now that we have deployed our sample AWS resources, we have a mix of compliant and non-compliant configurations that we can evaluate against FedRAMP requirements. In the next step, we'll perform compliance assessments on these resources.