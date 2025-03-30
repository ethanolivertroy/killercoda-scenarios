# Validating Network Policies and Security Context

FedRAMP requires proper network segmentation and traffic control (NIST 800-53 SC-7, AC-4). In Kubernetes, Network Policies enforce these requirements by restricting pod communication.

## Background

Network Policies in Kubernetes:
- Define which pods can communicate with each other
- Control ingress and egress traffic
- Are namespace-scoped resources
- Implement the "deny by default, allow by exception" security principle

## Authoritative References

This exercise is based on the following authoritative sources:

- **NIST SP 800-53 Rev. 5**: 
  - SC-7 (Boundary Protection)
  - AC-4 (Information Flow Enforcement)
  - SC-8 (Transmission Confidentiality and Integrity)

- **CIS Kubernetes Benchmark v1.6.1**:
  - Section 5.3: Network Policies and CNI
  - Control 5.3.1: Ensure that the CNI in use supports Network Policies
  - Control 5.3.2: Ensure that all Namespaces have Network Policies defined

- **NIST SP 800-204B**:
  - Section 4.3: Mutual TLS Authentication Between Services
  - Section 6.4: Network Segmentation and Traffic Control

- **Kubernetes Network Policies Documentation**:
  - [Official Kubernetes Network Policies Guide](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

- **OWASP Kubernetes Security Cheat Sheet**:
  - Section: Network Segmentation

For more detailed information, see `/root/authoritative-references.md` after completing this scenario.

## Task 1: Analyze the current network policy configuration

First, check for existing network policies:

```bash
kubectl get networkpolicies --all-namespaces
```{{exec}}

Let's create a sample application deployment to test network policies:

```bash
kubectl create deployment frontend --image=nginx --port=80 -n fedramp-demo
kubectl create deployment backend --image=nginx --port=80 -n fedramp-demo
kubectl expose deployment frontend --port=80 -n fedramp-demo
kubectl expose deployment backend --port=80 -n fedramp-demo
```{{exec}}

## Task 2: Create a compliant network policy

For FedRAMP compliance, we need to implement the principle of least privilege for network communication:

```bash
cat << EOF > /root/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-backend-only
  namespace: fedramp-demo
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF

kubectl apply -f /root/network-policy.yaml
```{{exec}}

Let's verify that the network policy was created:

```bash
kubectl get networkpolicy -n fedramp-demo
```{{exec}}

## Side-by-Side Compliance Comparison

Let's examine a side-by-side comparison of non-compliant vs. FedRAMP-compliant Network Policy configurations:

```bash
grep -A14 "Network Policy Examples" /root/compliance-examples.md
```{{exec}}

Notice the key differences:
- Non-compliant clusters have no network policies defined
- Compliant network policies explicitly define both ingress and egress rules
- Compliant policies use specific selectors for pods and namespaces
- Compliant policies define specific ports and protocols

To see the complete set of Network Policy compliance examples:

```bash
grep -A60 "Network Policy Examples" /root/compliance-examples.md
```{{exec}}

The FedRAMP-compliant example also demonstrates appropriate:
- Specific port restrictions for both ingress and egress
- Namespace isolation for multi-tenant environments
- DNS access for core functionality

## Task 3: Perform a FedRAMP security audit

Now let's create a comprehensive audit script that checks multiple FedRAMP compliance aspects:

```bash
cat << EOF > /root/fedramp-k8s-audit.sh
#!/bin/bash

echo "==============================================="
echo "Kubernetes FedRAMP Compliance Audit"
echo "Based on NIST 800-53 Controls"
echo "==============================================="

echo
echo "## 1. RBAC Audit (AC-2, AC-3, AC-6)"
echo "Checking for overly permissive roles..."
kubectl get clusterroles -o json | jq '.items[] | select(.rules[] | (.resources | index("*")) and (.verbs | index("*"))) | .metadata.name'

echo
echo "## 2. Pod Security Standards Audit (SC-7, CM-7, AC-6)"
echo "Checking for privileged containers..."
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.containers[] | .securityContext.privileged == true) | .metadata.namespace + "/" + .metadata.name'

echo "Checking for containers with hostNetwork..."
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.hostNetwork == true) | .metadata.namespace + "/" + .metadata.name'

echo
echo "## 3. Network Policy Audit (SC-7, AC-4)"
echo "Namespaces without NetworkPolicies (potential compliance issue):"
for ns in \$(kubectl get ns -o custom-columns=NAME:.metadata.name --no-headers); do
  if [ \$(kubectl get netpol -n \$ns -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null | wc -l) -eq 0 ]; then
    echo "- \$ns"
  fi
done

echo
echo "## 4. Secrets Management Audit (IA-5, SC-12, SC-13)"
echo "Checking for secret references in pod specs..."
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.containers[].env[]?.valueFrom.secretKeyRef != null) | .metadata.namespace + "/" + .metadata.name'

echo
echo "## 5. Logging and Monitoring Audit (AU-2, AU-3, AU-12)"
echo "Checking for log volume mounts..."
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.containers[].volumeMounts[]?.name | test(".*log.*";"i")) | .metadata.namespace + "/" + .metadata.name'

echo
echo "==============================================="
echo "FedRAMP Compliance Recommendations:"
echo "1. Implement Pod Security Standards in all namespaces"
echo "2. Restrict RBAC permissions to follow least privilege"
echo "3. Apply NetworkPolicies to isolate workloads"
echo "4. Use Kubernetes Secrets properly, consider external secrets management"
echo "5. Implement proper logging and monitoring"
echo "==============================================="
EOF

chmod +x /root/fedramp-k8s-audit.sh
```{{exec}}

Run the audit script to get a comprehensive FedRAMP compliance assessment:

```bash
/root/fedramp-k8s-audit.sh
```{{exec}}

## Task 4: Document compliance findings

FedRAMP requires comprehensive documentation of security controls. Let's create a simple findings report:

```bash
cat << EOF > /root/fedramp-findings.md
# Kubernetes FedRAMP Compliance Findings

## Non-compliant items identified:

1. **RBAC Issues**
   - Overly permissive roles with wildcard permissions
   - ServiceAccounts with excessive privileges

2. **Container Security Issues**
   - Privileged containers 
   - Containers using host namespaces
   - Missing SecurityContext configurations

3. **Network Security Issues**
   - Missing Network Policies
   - Lack of network segmentation

## Remediation Plan:

1. **RBAC Remediation**
   - Replace wildcard permissions with specific resource/verb combinations
   - Implement role aggregation for complex permissions
   - Review all ServiceAccount bindings

2. **Container Security Remediation**
   - Enforce Pod Security Standards at "restricted" level
   - Implement proper SecurityContext
   - Remove privileged access and capability requirements

3. **Network Security Remediation**
   - Implement default deny policies
   - Create allow policies based on application requirements
   - Document all network flows for compliance evidence

This documentation serves as evidence for FedRAMP AC-2, AC-3, AC-6, SC-7, CM-7 controls.
EOF

echo "Report generated: /root/fedramp-findings.md"
```{{exec}}

## Real-World Case Study: Network Security Issues

Let's examine a real-world case study related to network security issues:

```bash
grep -A20 "Case Study 8: Kubernetes Cryptomining" /root/kubernetes-security-case-studies.md
```{{exec}}

This case study shows how exposed components without proper network controls can lead to security breaches. The implementation of network policies and proper boundary protection, as required by FedRAMP SC-7, could have prevented this incident.

Let's look at another example related to container registry security:

```bash
grep -A20 "Case Study 7: Docker Hub" /root/kubernetes-security-case-studies.md
```{{exec}}

## Common Attack Patterns

To conclude our workshop, let's review the common attack patterns identified across these case studies:

```bash
grep -A20 "Common Vulnerabilities" /root/kubernetes-security-case-studies.md
```{{exec}}

These patterns highlight why FedRAMP compliance is critical for securing Kubernetes environments. By implementing the controls we've learned in this workshop, you can protect your clusters from these common attack vectors.

You've now completed a basic FedRAMP security audit for Kubernetes!