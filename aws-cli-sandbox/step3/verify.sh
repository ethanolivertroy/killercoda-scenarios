#!/bin/bash

# Check if LocalStack is running
if ! docker ps | grep -q localstack; then
  echo "LocalStack container is not running"
  exit 1
fi

# Check if SNS topic was created
SNS_TOPICS=$(aws sns list-topics --query 'Topics[*].TopicArn' --output text | wc -w)
if [ "$SNS_TOPICS" -lt 1 ]; then
  echo "No SNS topics found. Please create the notification topic."
  exit 1
fi

# Check if SQS queue was created
SQS_QUEUES=$(aws sqs list-queues --query 'QueueUrls' --output text | wc -w)
if [ "$SQS_QUEUES" -lt 1 ]; then
  echo "No SQS queues found. Please create the notification queue."
  exit 1
fi

# Check if CloudFormation stack was created
CF_STACKS=$(aws cloudformation list-stacks --query 'StackSummaries[*].StackName' --output text | wc -w)
if [ "$CF_STACKS" -lt 1 ]; then
  echo "No CloudFormation stacks found. Please create a stack."
  exit 1
fi

# Check if test files were created
if [ ! -f /tmp/simple-stack.yaml ]; then
  echo "CloudFormation template not found at /tmp/simple-stack.yaml"
  exit 1
fi

echo "Step 3 verification successful!"
exit 0