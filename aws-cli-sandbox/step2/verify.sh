#!/bin/bash

# Check if LocalStack is running
if ! docker ps | grep -q localstack; then
  echo "LocalStack container is not running"
  exit 1
fi

# Check if Lambda function was created
LAMBDA_COUNT=$(aws lambda list-functions --query 'Functions[*].FunctionName' --output text | wc -w)
if [ "$LAMBDA_COUNT" -lt 1 ]; then
  echo "No Lambda functions found. Please create at least one Lambda function."
  exit 1
fi

# Check if Lambda function zip file was created
if [ ! -f /tmp/lambda_function.zip ]; then
  echo "Lambda function zip file not found at /tmp/lambda_function.zip"
  exit 1
fi

# Check if test file exists
if [ ! -f /tmp/lambda_function.py ]; then
  echo "Lambda function source file not found at /tmp/lambda_function.py"
  exit 1
fi

echo "Step 2 verification successful!"
exit 0