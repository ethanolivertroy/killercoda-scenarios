#!/bin/bash

# Display setup message
echo "Setting up AWS CLI Sandbox environment with LocalStack..."
echo "This may take a few minutes..."

# Update apt and install required packages
apt-get update
apt-get install -y docker.io python3-pip jq curl unzip zip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install Python dependencies
pip3 install awscli-local boto3

# Pull and start LocalStack
echo "Starting LocalStack..."
docker pull localstack/localstack:latest
docker run -d --name localstack -p 4566:4566 -p 4571:4571 -e DEFAULT_REGION=us-east-1 localstack/localstack:latest

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
timeout 60 bash -c 'until docker logs localstack 2>&1 | grep -q "Ready."; do sleep 2; done'

# Configure AWS CLI to work with LocalStack
mkdir -p ~/.aws
cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
endpoint_url = http://localhost:4566
EOF

cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF

# Set up environment variables for easier AWS CLI usage
echo 'export AWS_ENDPOINT_URL=http://localhost:4566' >> ~/.bashrc
echo 'alias aws="aws --endpoint-url=\$AWS_ENDPOINT_URL"' >> ~/.bashrc
source ~/.bashrc

# Create a .env file in root directory
cat > /root/.env << EOF
AWS_ENDPOINT_URL=http://localhost:4566
EOF

# Create a simple Lambda function template
mkdir -p /tmp
cat > /tmp/lambda_function.py << EOF
def handler(event, context):
    print("Lambda function invoked!")
    response = {
        "statusCode": 200,
        "body": "Hello from Lambda!"
    }
    return response
EOF

# Create a basic IAM role policy for Lambda
cat > /tmp/lambda-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create helpful scripts for common tasks
cat > /root/create-lambda-package.sh << EOF
#!/bin/bash
cd /tmp
zip -r lambda_function.zip lambda_function.py
echo "Lambda package created at /tmp/lambda_function.zip"
EOF
chmod +x /root/create-lambda-package.sh

echo "Setup completed successfully."
echo "LocalStack is running and AWS CLI is configured to use the local endpoint."
echo "You can now proceed with the scenario."