# Authoritative References for Kubernetes FedRAMP Compliance

## NIST Publications

### NIST Special Publication 800-53 Rev. 5
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final) - Security and Privacy Controls for Information Systems and Organizations
- Provides the security control framework for FedRAMP compliance
- Core controls applicable to Kubernetes:
  - AC-2: Account Management
  - AC-3: Access Enforcement
  - AC-4: Information Flow Enforcement
  - AC-6: Least Privilege
  - AU-2: Audit Events
  - CM-6: Configuration Settings
  - CM-7: Least Functionality
  - SC-7: Boundary Protection
  - SC-8: Transmission Confidentiality and Integrity
  - SC-28: Protection of Information at Rest

### NIST Special Publication 800-204B
- [NIST SP 800-204B](https://csrc.nist.gov/publications/detail/sp/800-204b/final) - Attribute-based Access Control for Microservices-based Applications Using a Service Mesh
- Provides security strategies for containerized environments
- Directly applicable to Kubernetes service mesh implementations

### NIST Cybersecurity Framework
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework) - Core functions: Identify, Protect, Detect, Respond, Recover
- Maps well to Kubernetes security controls and practices

## CIS Kubernetes Benchmark

### CIS Kubernetes Benchmark v1.6.1
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes) - Industry-standard secure configuration guidance
- Sections directly relevant to this scenario:
  - 1.2: API Server
  - 3.2: RBAC and Service Accounts
  - 4.2: Pod Security Policies (now Pod Security Standards)
  - 5.2: Policies
  - 5.3: Network Policies and CNI
  - 5.7: General Policies

### CIS EKS Benchmark v1.0.1
- [CIS Amazon EKS Benchmark](https://www.cisecurity.org/benchmark/kubernetes) - EKS-specific security guidance
- Useful for FedRAMP assessments on AWS environments

## Kubernetes Security Documentation

### Pod Security Standards
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) - Official Kubernetes documentation
- Defines Privileged, Baseline, and Restricted policies
- Used in Step 2 of this scenario

### RBAC Documentation
- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) - Official Kubernetes documentation
- Comprehensive guide to role-based access control in Kubernetes
- Used in Step 1 of this scenario

### Network Policies
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) - Official Kubernetes documentation
- Guide to configuring network security in Kubernetes clusters
- Used in Step 3 of this scenario

## FedRAMP Documentation

### FedRAMP Security Controls Baseline
- [FedRAMP Security Controls Baseline](https://www.fedramp.gov/assets/resources/documents/FedRAMP_Security_Controls_Baseline.xlsx) - Excel spreadsheet of required controls
- Provides the compliance requirements for all FedRAMP authorization levels (Low, Moderate, High)

### FedRAMP Authorization Playbook
- [FedRAMP Authorization Playbook](https://www.fedramp.gov/assets/resources/documents/FedRAMP_Authorization_Playbook.pdf) - Guide to the FedRAMP authorization process
- Understanding this process helps contextualize Kubernetes security for FedRAMP compliance

## Cloud Native Security Resources

### CNCF Security Best Practices
- [CNCF TAG Security Documentation](https://github.com/cncf/tag-security/tree/main/security-whitepaper) - Cloud Native Security Whitepaper
- Industry guidance on securing cloud native applications, including Kubernetes

### Kubernetes Security Cheat Sheet
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html) - OWASP security guidance
- Concise reference for Kubernetes security best practices

## Tools for Kubernetes Compliance Assessment

### kube-bench
- [kube-bench](https://github.com/aquasecurity/kube-bench) - CIS Kubernetes Benchmark checking tool
- Automates compliance checking against CIS benchmarks

### OPA/Gatekeeper
- [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper) - Policy enforcement for Kubernetes
- Enables automated compliance checking and enforcement

### Falco
- [Falco](https://falco.org/) - Runtime security monitoring
- Detects anomalous activity and security violations in real-time