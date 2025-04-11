#!/bin/bash

# Check if LocalStack is running
if ! docker ps | grep -q localstack; then
  echo "LocalStack container is not running"
  exit 1
fi

# Check if we can connect to LocalStack
if ! aws --endpoint-url=http://localhost:4566 s3 ls &>/dev/null; then
  echo "Cannot connect to LocalStack endpoint"
  exit 1
fi

# Check if resources were created
BUCKETS=$(aws --endpoint-url=http://localhost:4566 s3 ls | wc -l)
USERS=$(aws --endpoint-url=http://localhost:4566 iam list-users --query 'Users[*].UserName' --output text | wc -w)
POLICIES=$(aws --endpoint-url=http://localhost:4566 iam list-policies --scope Local --query 'Policies[*].PolicyName' --output text | wc -w)
TRAILS=$(aws --endpoint-url=http://localhost:4566 cloudtrail list-trails --query 'Trails[*].Name' --output text | wc -w)

if [ "$BUCKETS" -lt 3 ] || [ "$USERS" -lt 2 ] || [ "$POLICIES" -lt 2 ] || [ "$TRAILS" -lt 1 ]; then
  echo "Not all required resources have been created"
  echo "Found $BUCKETS buckets (need 3), $USERS users (need 2), $POLICIES policies (need 2), $TRAILS trails (need 1)"
  exit 1
fi

echo "Step 1 verification successful!"
exit 0