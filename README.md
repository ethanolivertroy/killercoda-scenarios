# Interactive Killercoda Learning Scenarios

This repository contains interactive learning scenarios built for the [Killercoda](https://killercoda.com/) platform. These hands-on environments allow users to gain practical experience with various cloud-native technologies without needing to set up complex infrastructure locally.

## Available Scenarios

### 1. AWS CLI Sandbox with LocalStack

![AWS](https://img.shields.io/badge/AWS-CLI-FF9900)
![LocalStack](https://img.shields.io/badge/LocalStack-Testing-4D27AA)
![DevOps](https://img.shields.io/badge/DevOps-Skills-0078D6)

This scenario provides a hands-on sandbox environment for AWS CLI practice using [LocalStack](https://localstack.cloud/), allowing you to experiment with AWS services locally without any cloud costs.

**What You'll Learn:**
- How to set up and use LocalStack to simulate AWS services locally
- How to work with fundamental AWS CLI commands for S3, IAM, and DynamoDB
- How to build more complex scenarios with Lambda, SNS/SQS, and API Gateway
- How to deploy infrastructure as code using CloudFormation templates
- How to use advanced AWS CLI techniques like JMESPath filtering and resource management

**Ideal For:**
- Developers wanting to practice AWS CLI commands
- DevOps engineers building automation scripts
- Cloud architects testing infrastructure configurations
- Anyone preparing for AWS certification exams

**Resources:**
- [LocalStack Documentation](https://docs.localstack.cloud/getting-started/)
- [AWS CLI Documentation](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [JMESPath Query Language](https://jmespath.org/) (for filtering AWS CLI output)

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/aws-cli-sandbox)

### 2. Kubernetes Policy Engines

![OPA Gatekeeper](https://img.shields.io/badge/OPA-Gatekeeper-000000)
![Kyverno](https://img.shields.io/badge/Kyverno-Policy-2C90E8)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Security-326CE5)

This scenario teaches how to implement and audit Kubernetes policy engines (OPA Gatekeeper and Kyverno) to enforce security controls through policy as code.

**What You'll Learn:**
- How to install and configure OPA Gatekeeper and Kyverno in a Kubernetes cluster
- How to implement policies that enforce key security controls
- How to audit policy enforcement and generate documentation
- How to compare the two approaches and choose the right tool for your environment

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/kubernetes-policy-engines)

**Notes for instructors**: 
- If you encounter a webhook configuration error during OPA Gatekeeper installation, check that the resources list in the ValidatingWebhookConfiguration doesn't contain both '*' and specific resource names. The current version has been fixed to use only '*'.
- When creating Constraints, ensure that the corresponding ConstraintTemplates are fully established first. We've added a 10-second sleep between template creation and constraint application to address this.

### 3. Kubernetes Security Audit

![Kubernetes Security](https://img.shields.io/badge/Kubernetes-Security-326CE5)
![Security Controls](https://img.shields.io/badge/Security-Controls-0078D6)
![NIST Standards](https://img.shields.io/badge/NIST-800--53-00BFFF)

This scenario teaches security professionals and auditors how to assess Kubernetes deployments for security compliance based on industry standards.

**What You'll Learn:**
- How to audit Kubernetes RBAC for principle of least privilege
- How to assess Pod Security Standards compliance 
- How to validate Network Policies and security contexts
- How to generate compliance reports for documentation

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/kubernetes-fedramp-audit)

### 4. Istio Service Mesh Security

![Istio](https://img.shields.io/badge/Istio-Service%20Mesh-466BB0)
![Zero Trust](https://img.shields.io/badge/Zero-Trust-0078D6)
![NIST Standards](https://img.shields.io/badge/NIST-800--204-00BFFF)

This scenario teaches how to implement and assess security controls in Istio service meshes based on NIST 800-204 series guidance.

**What You'll Learn:**
- How to deploy a secure Istio service mesh
- How to configure and validate mTLS for service-to-service communication
- How to implement authentication and authorization controls
- How to audit service mesh security for compliance evidence

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/istio-fedramp-compliance)

### 5. Linkerd Service Mesh

![Linkerd](https://img.shields.io/badge/Linkerd-Service%20Mesh-2BEDA7)
![Zero Trust](https://img.shields.io/badge/Zero-Trust-0078D6)
![NIST Standards](https://img.shields.io/badge/NIST-800--204-00BFFF)

This scenario teaches how to implement and assess security controls in Linkerd service meshes using a lightweight, security-focused approach.

**What You'll Learn:**
- How to deploy a secure Linkerd service mesh
- How to implement and verify automatic mTLS encryption
- How to create authorization policies based on service identity
- How to generate security compliance evidence

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/linkerd-fedramp-compliance)

## Framework Coverage

These scenarios address topics including:

- **Cloud Services:**
  - Core AWS services and their CLI interactions
  - Event-driven architectures with SNS and SQS
  - Serverless application development with Lambda
  - Infrastructure as Code with CloudFormation
  - AWS resource tagging and organization
  - Advanced JMESPath queries for efficient AWS CLI use

- **Kubernetes Security:**
  - Access Control (RBAC, authentication, authorization)
  - Network security (Network Policies, CNI plugins)
  - Pod and container security contexts
  - Pod Security Standards and Pod Security Admission
  - Secrets management and secure storage

- **Service Mesh Security:**
  - Zero Trust security architecture 
  - Service-to-service authentication with mTLS
  - API security and authorization policies
  - Network segmentation and traffic management
  - Observability and security monitoring

- **Policy as Code:**
  - OPA Gatekeeper (Rego-based policies)
  - Kyverno (YAML-based policies)
  - Preventative security controls through admission control
  - Policy enforcement and audit reporting

## Getting Started

1. Visit [Killercoda](https://killercoda.com) to run these scenarios in your browser
2. No installation required - everything runs in a web-based terminal
3. Each scenario provides step-by-step instructions with verification checks

## Contributing

We welcome contributions to enhance these scenarios! Please submit a pull request with any improvements or additional scenarios related to:
- Cloud service sandboxes (AWS, GCP, Azure)
- Kubernetes security and best practices
- Service mesh configurations and security
- Infrastructure as Code examples
- DevOps and SRE practices

## License

This project is licensed under the MIT License - see the LICENSE file for details.