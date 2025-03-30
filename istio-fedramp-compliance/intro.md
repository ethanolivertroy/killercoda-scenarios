# Istio Service Mesh Security for FedRAMP Compliance

Welcome to the Istio Service Mesh Security for FedRAMP Compliance workshop!

In this scenario, you'll learn how to implement and assess security controls in Istio service meshes to meet FedRAMP requirements based on NIST 800-53 controls and NIST 800-204 series guidance for microservices.

## What you'll learn

- How to deploy a secure, FedRAMP-compliant Istio service mesh
- How to configure and validate mutual TLS (mTLS) for service-to-service communication
- How to implement authentication controls aligned with NIST requirements
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

You can review a summary of this guidance at any time:

```bash
cat /root/nist-service-mesh-guidance.md
```{{exec}}

## Environment Setup

Your environment is a 2-node Kubernetes cluster. During this workshop, we'll install Istio and deploy sample microservices to demonstrate security concepts.

Let's get started by setting up a FedRAMP-compliant Istio service mesh!