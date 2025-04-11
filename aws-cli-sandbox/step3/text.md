# Advanced AWS CLI Techniques & Resource Cleanup

In this final step, we will explore:
1. Creating AWS resource relationships
2. Working with CloudFormation templates
3. Using advanced AWS CLI filtering and queries
4. Cleaning up resources properly

## Creating Resource Relationships

Let's create some related AWS resources to simulate a typical application architecture:

```bash
# Create an SNS topic for notifications
aws sns create-topic --name notification-topic

# Create an SQS queue to subscribe to the topic
aws sqs create-queue --queue-name notification-queue

# Subscribe the SQS queue to the SNS topic
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:000000000000:notification-topic \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:notification-queue
```{{exec}}

Let's verify the subscription:

```bash
# List SNS subscriptions
aws sns list-subscriptions

# List SQS queues
aws sqs list-queues
```{{exec}}

## Working with CloudFormation Templates

CloudFormation allows you to define infrastructure as code. LocalStack supports basic CloudFormation functionality:

```bash
# Create a simple CloudFormation template
cat << EOF > /tmp/simple-stack.yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  MyS3Bucket:
    Type: 'AWS::S3::Bucket'
    Properties:
      BucketName: cf-created-bucket
  
  MyDynamoDBTable:
    Type: 'AWS::DynamoDB::Table'
    Properties:
      TableName: cf-users-table
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      ProvisionedThroughput:
        ReadCapacityUnits: 5
        WriteCapacityUnits: 5
EOF

# Deploy the CloudFormation stack
aws cloudformation create-stack \
  --stack-name simple-app-stack \
  --template-body file:///tmp/simple-stack.yaml
```{{exec}}

Let's check our stack and the resources it created:

```bash
# List stacks
aws cloudformation list-stacks

# List resources in the stack
aws cloudformation list-stack-resources \
  --stack-name simple-app-stack

# Verify the S3 bucket was created
aws s3 ls

# Verify the DynamoDB table was created
aws dynamodb list-tables
```{{exec}}

## Advanced AWS CLI Filtering and Queries

The AWS CLI supports powerful filtering and query capabilities using the `--query` parameter with JMESPath syntax:

```bash
# List only bucket names
aws s3api list-buckets --query 'Buckets[].Name'

# List DynamoDB tables with creation dates
aws dynamodb list-tables --query 'TableNames'

# Filter S3 objects by prefix
aws s3api list-objects --bucket my-test-bucket --query 'Contents[?starts_with(Key, `test`)]'
```{{exec}}

Let's try more complex filtering by creating some test objects:

```bash
# Create test files
echo "file1 content" > /tmp/file1.txt
echo "file2 content" > /tmp/file2.txt
echo "config content" > /tmp/config.json

# Upload files to S3
aws s3 cp /tmp/file1.txt s3://my-test-bucket/test/file1.txt
aws s3 cp /tmp/file2.txt s3://my-test-bucket/test/file2.txt
aws s3 cp /tmp/config.json s3://my-test-bucket/config/config.json

# List objects with advanced filtering
aws s3api list-objects --bucket my-test-bucket \
  --query "Contents[?contains(Key, 'test/')].{Key: Key, Size: Size}"
```{{exec}}

## Resource Cleanup

It's important to clean up AWS resources when you're done to prevent unexpected charges (in real AWS) or resource conflicts:

```bash
# Delete S3 objects
aws s3 rm s3://my-test-bucket --recursive

# Delete S3 buckets
aws s3 rb s3://my-test-bucket --force
aws s3 rb s3://cf-created-bucket --force

# Delete DynamoDB tables
aws dynamodb delete-table --table-name users-table
aws dynamodb delete-table --table-name cf-users-table

# Delete SQS queue
aws sqs delete-queue --queue-url https://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/notification-queue

# Delete SNS topic
aws sns delete-topic --topic-arn arn:aws:sns:us-east-1:000000000000:notification-topic

# Delete Lambda function
aws lambda delete-function --function-name my-test-function

# Delete CloudFormation stack (this will delete all resources in the stack)
aws cloudformation delete-stack --stack-name simple-app-stack
```{{exec}}

Verify that resources have been deleted:

```bash
# Check S3 buckets
aws s3 ls

# Check DynamoDB tables
aws dynamodb list-tables

# Check Lambda functions
aws lambda list-functions

# Check CloudFormation stacks
aws cloudformation list-stacks
```{{exec}}

## Conclusion

You've now learned how to:
1. Create relationships between AWS resources (SNS-SQS integration)
2. Use CloudFormation for defining infrastructure as code
3. Apply advanced filtering and querying to AWS CLI commands
4. Properly clean up AWS resources

These skills will help you work more efficiently with AWS services in both real AWS environments and LocalStack testing environments.