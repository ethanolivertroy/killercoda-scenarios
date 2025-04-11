# Kubernetes & Cloud Interactive Learning Scenarios

This repository contains interactive Killercoda scenarios focused on Kubernetes security, service mesh configurations, and AWS cloud skills. Most scenarios address FedRAMP security compliance, while the AWS CLI sandbox provides general hands-on practice with AWS services.

## Available Scenarios

### 1. Kubernetes FedRAMP Security Audit

![Kubernetes Security](https://img.shields.io/badge/Kubernetes-Security-326CE5)
![FedRAMP Compliance](https://img.shields.io/badge/FedRAMP-Compliance-0078D6)
![NIST Standards](https://img.shields.io/badge/NIST-800--53-00BFFF)

This scenario teaches security professionals and auditors how to assess Kubernetes deployments for FedRAMP compliance based on NIST 800-53 security controls.

**What You'll Learn:**
- How to audit Kubernetes RBAC for principle of least privilege
- How to assess Pod Security Standards compliance 
- How to validate Network Policies and security contexts
- How to generate compliance reports for FedRAMP documentation

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/kubernetes-fedramp-audit)

### 2. Istio Service Mesh Security for FedRAMP Compliance

![Istio](https://img.shields.io/badge/Istio-Service%20Mesh-466BB0)
![FedRAMP Compliance](https://img.shields.io/badge/FedRAMP-Compliance-0078D6)
![NIST Standards](https://img.shields.io/badge/NIST-800--204-00BFFF)

This scenario teaches how to implement and assess security controls in Istio service meshes to meet FedRAMP requirements based on NIST 800-53 controls and NIST 800-204 series guidance.

**What You'll Learn:**
- How to deploy a secure, FedRAMP-compliant Istio service mesh
- How to configure and validate mTLS for service-to-service communication
- How to implement authentication and authorization controls
- How to audit service mesh security for compliance evidence

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/istio-fedramp-compliance)

### 3. Linkerd Service Mesh for FedRAMP Compliance

![Linkerd](https://img.shields.io/badge/Linkerd-Service%20Mesh-2BEDA7)
![FedRAMP Compliance](https://img.shields.io/badge/FedRAMP-Compliance-0078D6)
![NIST Standards](https://img.shields.io/badge/NIST-800--204-00BFFF)

This scenario teaches how to implement and assess security controls in Linkerd service meshes for FedRAMP compliance based on NIST guidance, using a lightweight, security-focused approach.

**What You'll Learn:**
- How to deploy a secure, FedRAMP-compliant Linkerd service mesh
- How to implement and verify automatic mTLS encryption
- How to create authorization policies based on service identity
- How to generate compliance evidence for FedRAMP audits

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/linkerd-fedramp-compliance)

### 4. Kubernetes Policy Engines for FedRAMP Compliance

![OPA Gatekeeper](https://img.shields.io/badge/OPA-Gatekeeper-000000)
![Kyverno](https://img.shields.io/badge/Kyverno-Policy-2C90E8)
![FedRAMP Compliance](https://img.shields.io/badge/FedRAMP-Compliance-0078D6)
![NIST Standards](https://img.shields.io/badge/NIST-800--53-00BFFF)

This scenario teaches how to implement and audit Kubernetes policy engines (OPA Gatekeeper and Kyverno) to enforce FedRAMP security controls through policy as code.

**What You'll Learn:**
- How to install and configure OPA Gatekeeper and Kyverno in a Kubernetes cluster
- How to implement policies that enforce key FedRAMP security controls
- How to audit policy enforcement and generate compliance documentation
- How to compare the two approaches and choose the right tool for your environment

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/kubernetes-policy-engines)

**Notes for instructors**: 
- If you encounter a webhook configuration error during OPA Gatekeeper installation, check that the resources list in the ValidatingWebhookConfiguration doesn't contain both '*' and specific resource names. The current version has been fixed to use only '*'.
- When creating Constraints, ensure that the corresponding ConstraintTemplates are fully established first. We've added a 10-second sleep between template creation and constraint application to address this.

### 5. AWS CLI Sandbox with LocalStack

![AWS](https://img.shields.io/badge/AWS-CLI-FF9900)
![LocalStack](https://img.shields.io/badge/LocalStack-Testing-4D27AA)
![DevOps](https://img.shields.io/badge/DevOps-Skills-0078D6)

This scenario provides a hands-on sandbox environment for AWS CLI practice using LocalStack, allowing you to experiment with AWS services locally without any cloud costs. Unlike the other scenarios in this repository, this one focuses purely on AWS skill-building rather than compliance.

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

[Run This Scenario](https://killercoda.com/ethanolivertroy/scenario/aws-cli-sandbox)

## Compliance Frameworks Covered

These scenarios address security controls from:

- **NIST SP 800-53 Rev. 5:** Security and Privacy Controls
  - Access Control (AC-2, AC-3, AC-6)
  - Identification and Authentication (IA-2, IA-3)
  - System and Communications Protection (SC-7, SC-8, SC-13)
  - Audit and Accountability (AU-2, AU-12)
  - Configuration Management (CM-7, CM-8)
  - System and Information Integrity (SI-7)

- **NIST SP 800-204 Series:** Security for Microservices
  - Zero Trust Security Architecture 
  - Service-to-Service Authentication
  - API Security
  - Network Segmentation

- **Policy as Code Frameworks:**
  - OPA Gatekeeper (Rego-based policies)
  - Kyverno (YAML-based policies)
  - Preventative security controls through admission control
  
- **AWS CLI Sandbox (Non-Compliance Focused):**
  - Core AWS services and their CLI interactions
  - Event-driven architectures with SNS and SQS
  - Serverless application development with Lambda
  - Infrastructure as Code with CloudFormation
  - AWS resource tagging and organization
  - Advanced JMESPath queries for efficient AWS CLI use

## Getting Started

1. Visit [Killercoda](https://killercoda.com) to run these scenarios in your browser
2. No installation required - everything runs in a web-based terminal
3. Each scenario provides step-by-step instructions with verification checks

## Contributing

We welcome contributions to enhance these scenarios! Please submit a pull request with any improvements or additional scenarios related to:
- FedRAMP compliance for Kubernetes and service mesh environments
- Cloud native security practices
- AWS CLI and cloud service automation
- Infrastructure as Code examples

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

*Disclaimer: Most scenarios in this repository are educational resources intended to help understand FedRAMP compliance requirements in Kubernetes environments. They are not officially endorsed by FedRAMP or NIST and should not be considered as complete guidance for actual FedRAMP assessment preparation. The AWS CLI sandbox is a general skills-building tool not specifically focused on compliance.*