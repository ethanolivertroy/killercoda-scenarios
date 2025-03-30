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

## Compliance Frameworks Covered

These scenarios address security controls from:

- **NIST SP 800-53 Rev. 5:** Security and Privacy Controls
  - Access Control (AC-2, AC-3, AC-6)
  - Identification and Authentication (IA-2, IA-3)
  - System and Communications Protection (SC-7, SC-8, SC-13)
  - Audit and Accountability (AU-2, AU-12)

- **NIST SP 800-204 Series:** Security for Microservices
  - Zero Trust Security Architecture 
  - Service-to-Service Authentication
  - API Security
  - Network Segmentation

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