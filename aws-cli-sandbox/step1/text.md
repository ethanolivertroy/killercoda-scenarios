# Getting Started with AWS CLI and LocalStack

In this step, we will:
1. Verify LocalStack is running correctly
2. Test some basic AWS CLI commands
3. Create fundamental AWS resources

## Checking LocalStack Status

Let's verify that LocalStack is running properly:

```
# Check if the LocalStack container is running
docker ps | grep localstack
```{{exec}}

You should see the LocalStack container running. Now let's check that the AWS CLI is properly configured to work with LocalStack:

```
# Simple test command - should work without specifying endpoint URL
aws s3 ls
```{{exec}}

If the command works without any errors, your AWS CLI is correctly configured to use LocalStack!

## Exploring Available Services

LocalStack provides many AWS services for testing. Here's how to check what's available in the current version:

```
# Check LocalStack services
curl -s localhost:4566/_localstack/health | jq
```{{exec}}

## Basic AWS CLI Commands

Let's try some basic AWS CLI commands with various services:

### S3 Operations

```
# Create an S3 bucket
aws s3 mb s3://my-test-bucket
```{{exec}}

```
# List all S3 buckets
aws s3 ls
```{{exec}}

```
# Upload a file to your S3 bucket
echo "Hello, LocalStack!" > /tmp/hello.txt
aws s3 cp /tmp/hello.txt s3://my-test-bucket/
```{{exec}}

```
# List objects in your bucket
aws s3 ls s3://my-test-bucket/
```{{exec}}

### IAM Operations

```
# Create an IAM user
aws iam create-user --user-name test-user
```{{exec}}

```
# List IAM users
aws iam list-users
```{{exec}}

```
# Create an IAM policy
cat <<EOF > /tmp/test-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::my-test-bucket/*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name S3FullAccessPolicy \
  --policy-document file:///tmp/test-policy.json
```{{exec}}

### DynamoDB Operations

```
# Create a DynamoDB table
aws dynamodb create-table \
  --table-name MyTestTable \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```{{exec}}

```
# List DynamoDB tables
aws dynamodb list-tables
```{{exec}}

```
# Add an item to the table
aws dynamodb put-item \
  --table-name MyTestTable \
  --item '{"id": {"S": "001"}, "name": {"S": "Test Item"}, "value": {"N": "123"}}'
```{{exec}}

```
# Scan the table
aws dynamodb scan --table-name MyTestTable
```{{exec}}

## Using AWS CLI with Parameters

LocalStack supports most AWS CLI parameters, just like the real AWS:

```
# Using query parameter to filter results
aws iam list-users --query 'Users[].UserName'
```{{exec}}

```
# Using output formatting
aws dynamodb list-tables --output table
```{{exec}}

```
# Using regions (though LocalStack ignores them, it's good practice)
aws --region us-west-2 s3 ls
```{{exec}}

## Troubleshooting

If you ever need to see exactly what's happening with a command, you can add `--debug` to get detailed information:

```
# Debug an AWS CLI command
aws s3 ls --debug | head -20
```{{exec}}

## What's Next?

In the next step, we'll explore more advanced AWS CLI commands and show how to work with multiple services together. Feel free to experiment with any AWS CLI commands you'd like to test in this sandbox environment!