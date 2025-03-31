# FedRAMP Security Compliance Scenarios for Kubernetes

This repository contains interactive Killercoda scenarios focused on FedRAMP security compliance for Kubernetes and service mesh environments.

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

## Getting Started

1. Visit [Killercoda](https://killercoda.com) to run these scenarios in your browser
2. No installation required - everything runs in a web-based terminal
3. Each scenario provides step-by-step instructions with verification checks

## Contributing

We welcome contributions to enhance these scenarios! Please submit a pull request with any improvements or additional FedRAMP-focused scenarios.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

*Disclaimer: These scenarios are educational resources intended to help understand FedRAMP compliance requirements in Kubernetes environments. They are not officially endorsed by FedRAMP or NIST and should not be considered as complete guidance for actual FedRAMP assessment preparation.*