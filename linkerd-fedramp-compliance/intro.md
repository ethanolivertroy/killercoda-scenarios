# Linkerd Service Mesh Security for FedRAMP Compliance

Welcome to the Linkerd Service Mesh Security for FedRAMP Compliance workshop!

## What is Linkerd?

Linkerd is an ultralight, security-focused service mesh for Kubernetes. As a Cloud Native Computing Foundation (CNCF) graduated project, Linkerd provides a service mesh that is:

- **Simple and minimalist** with a focus on being the easiest service mesh to operate
- **Ultra-lightweight** with a slim control plane and tiny Rust-based proxies
- **Security-first** with automatic mTLS, policy enforcement, and advanced authorization controls

## What Problems Does Linkerd Solve?

Modern cloud-native applications face several challenges that Linkerd helps solve:

1. **Security Challenges**:
   - Service-to-service authentication and authorization
   - Transparent encryption with automatic mTLS
   - Certificate management and rotation
   - Zero-trust networking

2. **Operational Challenges**:
   - Service discovery and load balancing
   - Automatic retries and timeouts
   - Transparent proxy injection
   - Traffic splitting for canary deployments

3. **Observability Challenges**:
   - Golden metrics for all services
   - Distributed tracing
   - Service health monitoring
   - Real-time service dependency mapping

## Why Use Linkerd?

Organizations adopt Linkerd for several key benefits:

- **Simplicity**: Linkerd focuses on being the simplest and easiest service mesh to operate
- **Performance**: With its Rust-based micro-proxy, Linkerd has near-zero performance impact
- **Security-first Design**: Built from the ground up with security as a primary concern
- **Minimalist Philosophy**: Linkerd does what you need without unnecessary complexity
- **Compliance Enablement**: Linkerd makes it easier to implement and demonstrate compliance with security requirements

## Linkerd and FedRAMP Compliance

Linkerd is particularly valuable for FedRAMP compliance because it addresses many NIST 800-53 controls out of the box, including:

- **SC-8**: Transmission Confidentiality and Integrity (via automatic mTLS)
- **SC-12**: Cryptographic Key Establishment and Management (via automatic certificate management)
- **SC-17**: Public Key Infrastructure Certificates (via workload identity)
- **AC-3**: Access Enforcement (via authorization policies)
- **AC-4**: Information Flow Control (via network policies)
- **AC-6**: Least Privilege (via granular authorization rules)
- **IA-2/IA-3**: Identification and Authentication (via service identity)
- **IA-5**: Authenticator Management (via certificate rotation)
- **AU-2/AU-3**: Audit and Accountability (via access logging)
- **SI-4**: Information System Monitoring (via metrics and observability)

In this scenario, you'll learn how to implement and assess security controls in Linkerd service meshes to meet FedRAMP requirements based on NIST 800-53 controls and NIST 800-204 series guidance for microservices.

## What you'll learn

- How to deploy a secure, FedRAMP-compliant Linkerd service mesh
- How to configure and validate mutual TLS (mTLS) for service-to-service communication
- How to implement authentication and authorization controls aligned with NIST requirements
- How to audit authorization policies for least privilege
- How to assess and improve network security in a service mesh
- How to generate compliance evidence for FedRAMP documentation

## NIST Guidance for Service Mesh Security

This workshop is based on the following NIST publications:
- NIST SP 800-53 Rev. 5: Security and Privacy Controls
- NIST SP 800-204: Security Strategies for Microservices
- NIST SP 800-204A: Building Secure Microservices-based Applications
- NIST SP 800-204B: Attribute-based Access Control for Microservices
- NIST SP 800-204C: Implementation of DevSecOps for Microservices
- NIST SP 800-204D: Security Strategies for Container Runtimes and Orchestration in Microservices

You can review a summary of this guidance at any time:

```bash
cat /root/nist-linkerd-guidance.md
```{{exec}}

## Environment Setup

Your environment is a 2-node Kubernetes cluster. During this workshop, we'll install Linkerd and deploy sample microservices to demonstrate security concepts.

Let's get started by setting up a FedRAMP-compliant Linkerd service mesh!