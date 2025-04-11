# Working with More AWS Services in LocalStack

In this step, we will:
1. Explore additional AWS services in LocalStack
2. Create and interact with more complex resources
3. Learn how to combine multiple services together

## Lambda Functions

AWS Lambda is one of the most popular serverless services. Let's create a simple Lambda function:

```
# Create a simple Lambda function
cat <<EOF > /tmp/lambda_function.py
def handler(event, context):
    print("Hello from Lambda!")
    return {
        'statusCode': 200,
        'body': 'Function executed successfully!'
    }
EOF

# Zip the Lambda function (we've installed zip in the setup)
cd /tmp && zip lambda_function.zip lambda_function.py

# Return to home directory
cd ~
```{{exec}}

```
# Create an IAM role for Lambda (simplified for LocalStack)
ROLE_RESPONSE=$(aws iam create-role \
  --role-name lambda-role \
  --assume-role-policy-document file:///tmp/lambda-trust-policy.json)

# Get the role ARN
ROLE_ARN=$(echo $ROLE_RESPONSE | jq -r .Role.Arn)
echo "Created role with ARN: $ROLE_ARN"

# Wait a moment for the role to be available
sleep 2

# Create a simpler Lambda function for LocalStack compatibility
cat <<EOF > /tmp/simple_lambda.py
def handler(event, context):
    return {"message": "Hello from Lambda!"}
EOF

# Create a fresh zip file with the simple function
cd /tmp && rm -f lambda_function.zip && zip lambda_function.zip simple_lambda.py
cd ~

# Create the Lambda function with minimal settings for LocalStack
aws lambda create-function \
  --function-name my-test-function \
  --runtime python3.8 \
  --handler simple_lambda.handler \
  --zip-file fileb:///tmp/lambda_function.zip \
  --role $ROLE_ARN
```{{exec}}

```
# List Lambda functions
aws lambda list-functions
```{{exec}}

```
# Wait a moment for the function to be available
echo "Waiting for Lambda function to be ready..."
sleep 3

# Invoke the Lambda function
aws lambda invoke \
  --function-name my-test-function \
  --payload '{"key": "value"}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/lambda-output.json

# See the output (if successful)
if [ -f /tmp/lambda-output.json ]; then
  echo "Lambda function output:"
  cat /tmp/lambda-output.json
else
  echo "Invocation didn't produce output file. Checking function status:"
  aws lambda get-function --function-name my-test-function
fi
```{{exec}}

## SNS and SQS for Messaging

AWS SNS (Simple Notification Service) and SQS (Simple Queue Service) are commonly used for decoupled communication:

```
# Create an SNS topic
aws sns create-topic --name my-test-topic
```{{exec}}

```
# Create an SQS queue
aws sqs create-queue --queue-name my-test-queue
```{{exec}}

```
# List topics and queues
echo "SNS Topics:"
aws sns list-topics

echo "SQS Queues:"
aws sqs list-queues
```{{exec}}

```
# Subscribe the SQS queue to the SNS topic
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:000000000000:my-test-topic \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:my-test-queue
```{{exec}}

```
# Publish a message to the SNS topic
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:000000000000:my-test-topic \
  --message "Hello from SNS!"
```{{exec}}

```
# Receive messages from the SQS queue
aws sqs receive-message --queue-url http://localhost:4566/000000000000/my-test-queue
```{{exec}}

## API Gateway

Let's create a simple API endpoint with API Gateway:

```
# Create an API
API_RESPONSE=$(aws apigateway create-rest-api --name my-test-api)
echo "$API_RESPONSE"

# Extract the API ID and root resource ID directly using grep and cut to avoid JMESPath issues
API_ID=$(echo "$API_RESPONSE" | grep -o '"id": "[^"]*' | cut -d'"' -f4)
ROOT_ID=$(echo "$API_RESPONSE" | grep -o '"rootResourceId": "[^"]*' | cut -d'"' -f4)

echo "API ID: $API_ID"
echo "Root Resource ID: $ROOT_ID"
```{{exec}}

```
# List the APIs to confirm creation
aws apigateway get-rest-apis

# Get resources for the API we created
aws apigateway get-resources --rest-api-id $API_ID
```{{exec}}

```
# Create a resource
aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part "hello"

# List resources to get the new resource ID
RESOURCES_RESPONSE=$(aws apigateway get-resources --rest-api-id $API_ID)
echo "$RESOURCES_RESPONSE"
```{{exec}}

```
# Find the resource ID for the /hello path (using grep/cut to avoid JMESPath)
RESOURCES_LIST=$(aws apigateway get-resources --rest-api-id $API_ID)
echo "$RESOURCES_LIST" | grep -A 5 "/hello"
RESOURCE_ID=$(echo "$RESOURCES_LIST" | grep -A 2 "/hello" | grep -o '"id": "[^"]*' | head -1 | cut -d'"' -f4)
echo "Resource ID for /hello: $RESOURCE_ID"

# Create a GET method if we have a valid resource ID
if [ ! -z "$RESOURCE_ID" ]; then
  aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --authorization-type NONE
  echo "GET method created successfully"
else
  echo "Resource ID not found, skipping method creation"
fi
```{{exec}}

## CloudFormation Templates

AWS CloudFormation allows you to define infrastructure as code. LocalStack supports basic CloudFormation templates:

```
# Create a simple CloudFormation template
cat <<EOF > /tmp/cloudformation-template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  MyS3Bucket:
    Type: 'AWS::S3::Bucket'
    Properties:
      BucketName: cf-created-bucket
  
  MyDynamoDBTable:
    Type: 'AWS::DynamoDB::Table'
    Properties:
      TableName: cf-created-table
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
```{{exec}}

```
# Create a CloudFormation stack
aws cloudformation create-stack \
  --stack-name my-test-stack \
  --template-body file:///tmp/cloudformation-template.yaml
```{{exec}}

```
# List CloudFormation stacks
aws cloudformation list-stacks
```{{exec}}

```
# Check if resources were created
echo "S3 Buckets:"
aws s3 ls

echo "DynamoDB Tables:"
aws dynamodb list-tables
```{{exec}}

## Exploring Other Services

LocalStack Community Edition supports many other AWS services. Here are a few more examples:

### Secrets Manager

```
# Create a secret
aws secretsmanager create-secret \
  --name my-test-secret \
  --secret-string '{"username":"admin","password":"secret123"}'
```{{exec}}

```
# Get the secret
aws secretsmanager get-secret-value --secret-id my-test-secret
```{{exec}}

### CloudWatch Logs

```
# Create a log group
aws logs create-log-group --log-group-name my-test-logs
```{{exec}}

```
# List log groups
aws logs describe-log-groups
```{{exec}}

```
# Create a log stream
aws logs create-log-stream \
  --log-group-name my-test-logs \
  --log-stream-name my-test-stream
```{{exec}}

```
# Put log events
aws logs put-log-events \
  --log-group-name my-test-logs \
  --log-stream-name my-test-stream \
  --log-events timestamp=$(date +%s000),message="Test log message"
```{{exec}}

## Creating Your Own Tests

The real value of this sandbox is that you can experiment with any AWS CLI commands you need to test. Feel free to try out commands related to your specific workloads or scenarios!

In the next step, we'll look at how to set up more advanced scenarios and combine multiple services together.