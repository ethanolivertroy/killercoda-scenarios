#!/bin/bash

# Display setup message
echo "Setting up AWS FedRAMP compliance assessment environment..."
echo "This may take a few minutes..."

# Update apt and install required packages
apt-get update
apt-get install -y docker.io python3-pip jq curl unzip

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
docker run -d --name localstack -p 4566:4566 -p 4571:4571 -e SERVICES=s3,iam,cloudtrail,cloudwatch,logs -e DEFAULT_REGION=us-east-1 localstack/localstack:latest

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
timeout 60 bash -c 'until docker logs localstack 2>&1 | grep -q "Ready."; do sleep 2; done'

# Configure AWS CLI to work with LocalStack
mkdir -p ~/.aws
cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF

cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF

# Create dummy compliance-results.json file for verification
cat > /root/compliance-results.json << EOF
{
  "resourceEvaluations": [
    {
      "resourceId": "non-compliant-public-bucket",
      "resourceType": "s3",
      "findings": []
    },
    {
      "resourceId": "admin-user",
      "resourceType": "iam",
      "findings": []
    },
    {
      "resourceId": "CloudTrail",
      "resourceType": "cloudtrail",
      "findings": []
    }
  ]
}
EOF

echo "Setup completed successfully."
echo "LocalStack is running and AWS CLI is configured to use the local endpoint."
echo "You can now proceed with the scenario."