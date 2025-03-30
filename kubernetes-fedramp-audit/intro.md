# Kubernetes FedRAMP Security Audit Workshop

Welcome to the Kubernetes FedRAMP Security Audit workshop! 

In this scenario, you'll learn how to assess Kubernetes deployments for compliance with FedRAMP security requirements based on NIST 800-53 controls and Kubernetes security best practices.

## What you'll learn

- How to audit Kubernetes RBAC configurations for principle of least privilege
- How to assess Pod Security Standards compliance
- How to validate Network Policies and Security Context configurations
- How to generate compliance reports for FedRAMP documentation

This workshop is designed for security professionals, auditors, and cloud architects who need to validate Kubernetes deployments against FedRAMP requirements.

Your environment is a 2-node Kubernetes cluster with intentionally non-compliant resources deployed. Your task is to identify the compliance issues and recommend remediation steps.

## Authoritative References

Throughout this workshop, we'll refer to authoritative sources including:
- NIST Special Publication 800-53 Rev. 5
- CIS Kubernetes Benchmark v1.6.1
- NIST SP 800-204B
- Kubernetes official documentation
- CNCF Cloud Native Security resources

You can review these references at any time:

```bash
cat /root/authoritative-references.md
```{{exec}}

## Side-by-Side Compliance Examples

To help you understand FedRAMP compliance requirements in practice, we've provided side-by-side comparisons of non-compliant and compliant Kubernetes configurations:

```bash
ls -l /root/compliance-examples.md
```{{exec}}

This resource includes examples for:
- RBAC configurations
- Pod Security settings
- Network Policies
- Secret Management
- Resource Limits

You can explore specific examples during each step of this workshop.

## Real-World Kubernetes Security Case Studies

To emphasize the importance of FedRAMP compliance, we've included real-world case studies of Kubernetes security incidents:

```bash
ls -l /root/kubernetes-security-case-studies.md
```{{exec}}

These case studies include:
- Description of actual security incidents
- Attack vectors and vulnerabilities exploited
- Business impact of the security breaches
- How FedRAMP controls would have prevented the incidents
- Lessons learned for Kubernetes security

Review these case studies to understand the real-world implications of security vulnerabilities and the importance of proper security controls.

Let's get started!