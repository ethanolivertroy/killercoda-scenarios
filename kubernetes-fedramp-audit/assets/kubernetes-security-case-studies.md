# Real-World Kubernetes Security Incidents: Case Studies

This document presents real-world security incidents involving Kubernetes environments, their impact, root causes, and how proper FedRAMP compliance controls could have prevented them.

## Case Study 1: Tesla Cryptojacking Incident (2018)

### Incident Details
In 2018, attackers accessed Tesla's Kubernetes console, which was not password protected. They installed cryptocurrency mining software on Tesla's Kubernetes cluster to mine cryptocurrency using Tesla's compute resources.

### Attack Vector
- Exposed Kubernetes dashboard without authentication
- No network segmentation to restrict dashboard access
- Insufficient monitoring for unusual compute usage

### Impact
- Unauthorized compute resource consumption
- Potential exposure of sensitive data
- Reputational damage

### How FedRAMP Controls Would Have Prevented This
- **AC-3 (Access Enforcement)**: Proper access controls for the Kubernetes dashboard
- **SC-7 (Boundary Protection)**: Network segmentation to restrict dashboard access
- **SI-4 (Information System Monitoring)**: Detection of unusual compute resource usage
- **CM-7 (Least Functionality)**: Restricting exposed services

### Lessons Learned
1. Always enforce authentication for Kubernetes dashboards
2. Implement network policies to restrict access to management interfaces
3. Monitor for unusual resource usage patterns
4. Use Pod Security Standards to prevent unauthorized workloads

---

## Case Study 2: Capital One Data Breach (2019)

### Incident Details
While not exclusively a Kubernetes incident, the Capital One breach involved a server-side request forgery (SSRF) vulnerability that was exploited to access cloud metadata services and obtain IAM credentials. This type of vulnerability is also applicable to Kubernetes environments with misconfigured service accounts.

### Attack Vector
- SSRF vulnerability allowing metadata service access
- Overly permissive IAM roles assigned to service account
- Lack of network policy controls

### Impact
- Exposure of 100+ million customer records
- $80 million fine
- Significant damage to reputation

### How FedRAMP Controls Would Have Prevented This
- **AC-6 (Least Privilege)**: Limiting service account permissions
- **SC-7 (Boundary Protection)**: Blocking access to metadata services
- **CM-7 (Least Functionality)**: Disabling unnecessary features
- **SC-8 (Transmission Confidentiality and Integrity)**: Encrypting sensitive data

### Lessons Learned
1. Service accounts should have minimal permissions
2. Block access to cloud metadata services from containers that don't need it
3. Implement strict network policies
4. Monitor for unusual API access patterns

---

## Case Study 3: Shopify Kubernetes Infrastructure Access (2020)

### Incident Details
In 2020, Shopify discovered unauthorized access to their GitHub repositories by members of their infrastructure team. While not purely a Kubernetes incident, it highlighted the risks associated with privileged access to infrastructure code that manages Kubernetes environments.

### Attack Vector
- Insider threats with excessive privileges
- Lack of separation of duties
- Inadequate audit logging

### Impact
- Potential exposure of merchant data
- Access to infrastructure configuration
- Reputational damage

### How FedRAMP Controls Would Have Prevented This
- **AC-5 (Separation of Duties)**: Requiring multiple people to make sensitive changes
- **AC-6 (Least Privilege)**: Restricting access to only what's necessary
- **AU-2 (Audit Events)**: Logging and monitoring infrastructure access
- **SI-4 (Information System Monitoring)**: Detecting unusual access patterns

### Lessons Learned
1. Implement separation of duties for infrastructure access
2. Use just-in-time access for privileged operations
3. Maintain comprehensive audit logs
4. Implement continuous compliance monitoring

---

## Case Study 4: Microsoft Container Registry Vulnerability (2021)

### Incident Details
In 2021, Microsoft disclosed a vulnerability in Azure Container Registry (ACR) that could allow unauthorized access to repositories. This vulnerability affected Kubernetes environments pulling images from ACR.

### Attack Vector
- Token validation issues in the container registry
- Inadequate authentication controls
- Lack of image vulnerability scanning

### Impact
- Potential access to private container images
- Possibility of supply chain attacks
- Exfiltration of embedded secrets in images

### How FedRAMP Controls Would Have Prevented This
- **CM-10 (Software Usage Restrictions)**: Controlling image sources
- **SI-7 (Software, Firmware, and Information Integrity)**: Verifying image integrity
- **CM-11 (User-Installed Software)**: Controlling what can be deployed
- **RA-5 (Vulnerability Scanning)**: Scanning images for vulnerabilities

### Lessons Learned
1. Implement container image scanning and signing
2. Use private registries with strong access controls
3. Avoid embedding secrets in container images
4. Implement image pull policies to enforce security

---

## Case Study 5: Kube-proxy Privilege Escalation (CVE-2020-8558)

### Incident Details
In 2020, a vulnerability in kube-proxy allowed attackers to send network traffic to localhost services on the host network namespace, potentially leading to privilege escalation.

### Attack Vector
- Misconfiguration of kube-proxy
- Lack of network segmentation
- Missing host-level protections

### Impact
- Potential privilege escalation
- Access to sensitive localhost services
- Lateral movement within the cluster

### How FedRAMP Controls Would Have Prevented This
- **CM-6 (Configuration Settings)**: Properly configuring kube-proxy
- **SC-7 (Boundary Protection)**: Implementing network segmentation
- **SI-2 (Flaw Remediation)**: Promptly applying security patches
- **CM-7 (Least Functionality)**: Disabling unnecessary features

### Lessons Learned
1. Keep Kubernetes components updated with security patches
2. Implement strict network policies
3. Use Pod Security Standards to restrict host access
4. Regularly audit cluster configurations

---

## Case Study 6: Kubernetes API Server Vulnerability (CVE-2018-1002105)

### Incident Details
A severe privilege escalation vulnerability in Kubernetes allowed any user to establish a connection through the Kubernetes API server to a backend server, then send arbitrary requests authenticated by the API server's TLS credentials.

### Attack Vector
- Vulnerability in the Kubernetes API server's handling of upgrade requests
- Lack of adequate monitoring
- Excessive permissions for regular users

### Impact
- Complete compromise of the Kubernetes cluster
- Ability to execute arbitrary commands on any pod
- Access to all secrets in the cluster

### How FedRAMP Controls Would Have Prevented This
- **SI-2 (Flaw Remediation)**: Applying security patches promptly
- **AC-6 (Least Privilege)**: Limiting user permissions
- **AU-2 (Audit Events)**: Logging and monitoring API server access
- **CM-3 (Configuration Change Control)**: Testing changes before implementation

### Lessons Learned
1. Keep Kubernetes components updated with security patches
2. Implement strict RBAC controls
3. Monitor and audit API server activity
4. Maintain a vulnerability management program

---

## Case Study 7: Docker Hub Breach (2019)

### Incident Details
In 2019, Docker Hub experienced a security breach affecting approximately 190,000 accounts. This incident highlighted the risks of using public container registries without proper security controls.

### Attack Vector
- Unauthorized access to a database of user credentials
- Users with the same credentials across multiple services
- Lack of MFA for container registry access

### Impact
- Exposure of usernames, hashed passwords, and GitHub/Bitbucket tokens
- Potential supply chain attacks via compromised images
- Unauthorized access to connected resources

### How FedRAMP Controls Would Have Prevented This
- **IA-2 (Identification and Authentication)**: Implementing MFA
- **IA-5 (Authenticator Management)**: Proper credential management
- **SC-12 (Cryptographic Key Management)**: Secure token handling
- **SI-7 (Software, Firmware, and Information Integrity)**: Verifying image integrity

### Lessons Learned
1. Use private container registries for sensitive workloads
2. Implement multi-factor authentication for registry access
3. Regularly scan container images for vulnerabilities
4. Implement strict image pull policies

---

## Case Study 8: Kubernetes Cryptomining Attack via Exposed Etcd (2020)

### Incident Details
Attackers targeted exposed etcd instances to gain access to Kubernetes clusters and deploy cryptomining malware. The attackers exploited unsecured etcd ports (2379) exposed to the internet.

### Attack Vector
- Exposed etcd ports without authentication
- Lack of network segmentation
- Absence of resource limits on pods

### Impact
- Unauthorized deployment of cryptomining containers
- Excessive resource consumption
- Potential access to sensitive configuration data and secrets

### How FedRAMP Controls Would Have Prevented This
- **SC-7 (Boundary Protection)**: Restricting etcd access
- **AC-3 (Access Enforcement)**: Implementing etcd authentication
- **SC-8 (Transmission Confidentiality and Integrity)**: Encrypting etcd communication
- **SC-5 (Denial of Service Protection)**: Implementing resource limits

### Lessons Learned
1. Never expose etcd directly to the internet
2. Enable authentication and encryption for etcd
3. Implement network policies to restrict access to control plane components
4. Set resource limits on all containers and namespaces

---

## Summary: Common Patterns and FedRAMP Controls

Across these case studies, several patterns emerge that highlight the importance of FedRAMP security controls in Kubernetes environments:

### Common Vulnerabilities
1. **Excessive Permissions**: Violating least privilege principles
2. **Exposed Interfaces**: Management interfaces accessible without proper authentication
3. **Missing Network Controls**: Lack of network segmentation and policies
4. **Unpatched Components**: Failure to apply security updates
5. **Inadequate Monitoring**: Inability to detect unusual activity

### Key FedRAMP Controls That Would Have Prevented These Incidents
1. **AC-2, AC-3, AC-6**: Account management, access enforcement, and least privilege
2. **AU-2, AU-12**: Audit logging and monitoring
3. **CM-6, CM-7**: Secure configuration and least functionality
4. **SC-7, SC-8**: Boundary protection and data encryption
5. **SI-2, SI-4**: Vulnerability management and system monitoring

### Implementing These Controls in Your Kubernetes Environment
1. Implement strict RBAC policies with least privilege
2. Use Pod Security Standards at the 'restricted' level
3. Implement comprehensive network policies
4. Maintain a vulnerability management program
5. Deploy robust monitoring and logging solutions
6. Encrypt sensitive data at rest and in transit
7. Regularly audit and test your security controls

By learning from these real-world incidents and implementing FedRAMP-compliant controls, you can significantly enhance the security posture of your Kubernetes environments.