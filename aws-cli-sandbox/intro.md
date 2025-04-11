# AWS CLI Sandbox with LocalStack

## Introduction

Welcome to the AWS CLI Sandbox! This environment provides a safe, isolated playground for testing AWS CLI commands without accessing actual AWS resources or incurring any costs.

In this scenario, you will:

1. Set up LocalStack, a cloud service emulator that runs in a single container
2. Experiment with AWS CLI commands against various emulated AWS services
3. Create and manipulate AWS resources without worrying about costs or cleanup

## Environment Preparation

We'll be using LocalStack Community Edition to emulate AWS services locally. Let's get started:

```
# Run environment setup script
bash /root/setup.sh
```{{exec}}

This script will:
- Install Docker (required for LocalStack)
- Install and configure the AWS CLI
- Set up environment variables for easier AWS CLI usage
- Start the LocalStack container

> **Note:** We've configured the AWS CLI to automatically use the LocalStack endpoint. This allows you to use standard AWS CLI commands without having to specify the `--endpoint-url` parameter each time.

## Available AWS Services

The LocalStack Community Edition provides free emulation of many popular AWS services, including:

- **S3**: Object storage
- **IAM**: Identity and access management
- **Lambda**: Serverless compute
- **DynamoDB**: NoSQL database
- **SQS/SNS**: Messaging services
- **And many more**

## How to Use This Sandbox

This sandbox is a safe place to experiment with AWS CLI commands. Any resources you create exist only within the LocalStack container and will be automatically cleaned up when the session ends.

Feel free to:
- Test complex AWS CLI commands
- Create and delete resources repeatedly
- Experiment with IAM policies and permissions
- Practice using AWS services without fear of breaking anything

Let's begin by checking that our LocalStack environment is ready!