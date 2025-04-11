#!/bin/bash

# Check if LocalStack is running
if ! docker ps | grep -q localstack; then
  echo "LocalStack container is not running"
  exit 1
fi

# Check if we can connect to LocalStack
if ! aws s3 ls &>/dev/null; then
  echo "Cannot connect to LocalStack endpoint"
  exit 1
fi

# Check if basic resources were created
BUCKETS=$(aws s3 ls | wc -l)
if [ "$BUCKETS" -lt 1 ]; then
  echo "No S3 buckets found. Please create at least one bucket."
  exit 1
fi

# Check if a DynamoDB table was created
TABLES=$(aws dynamodb list-tables --query 'TableNames' --output text | wc -w)
if [ "$TABLES" -lt 1 ]; then
  echo "No DynamoDB tables found. Please create at least one table."
  exit 1
fi

# Check if IAM user was created
USERS=$(aws iam list-users --query 'Users[*].UserName' --output text | wc -w)
if [ "$USERS" -lt 1 ]; then
  echo "No IAM users found. Please create at least one user."
  exit 1
fi

echo "Step 1 verification successful!"
exit 0