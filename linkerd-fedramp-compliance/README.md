# Linkerd FedRAMP Compliance Workshop

This workshop demonstrates how to use Linkerd service mesh to implement security controls required for FedRAMP compliance.

## Workshop Overview

This interactive tutorial covers:

1. **Introduction to Linkerd and FedRAMP Requirements**
   - How service mesh helps meet NIST 800-53 controls

2. **Implementing mTLS and Security Policies**
   - Setting up automatic mTLS encryption
   - Creating identity-based authorization policies
   - Implementing HTTP-level access controls

3. **Auditing and Compliance Evidence**
   - Generating compliance evidence
   - Monitoring service mesh security

## Implementation Notes

The key security features demonstrated in this workshop include:

- **Automatic mTLS** - All service-to-service communication is encrypted
- **Service Identity** - Each service has a cryptographic identity
- **Authorization Policies** - Fine-grained access controls using:
  - Server resources (`policy.linkerd.io/v1beta3`)
  - ServerAuthorization resources (`policy.linkerd.io/v1beta1`) 
  - HTTPRoute resources (`policy.linkerd.io/v1beta3`)

## Workshop Files

- `intro.md` - Introduction to the workshop
- `step1/` - Installation and setup
- `step2/` - Implementing mTLS and security policies
- `step3/` - Auditing and compliance evidence
- `finish.md` - Summary and next steps
- `assets/` - Supporting files including:
  - `linkerd-policy-examples.yaml` - Examples of correctly formatted policy resources
  - Other reference materials

## FedRAMP Controls Addressed

This workshop demonstrates how Linkerd helps meet key FedRAMP controls including:

- SC-8 (Transmission Confidentiality)
- SC-13 (Cryptographic Protection)
- AC-3 (Access Enforcement)
- AC-4 (Information Flow Enforcement)
- IA-2 (Identification and Authentication)
- IA-5 (Authenticator Management)