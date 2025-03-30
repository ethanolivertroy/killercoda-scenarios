# Assessing Pod Security Standards Compliance

FedRAMP requires enforcement of strong system protection mechanisms (NIST 800-53 SC-7, CM-7, AC-6). In Kubernetes, Pod Security Standards (PSS) provide a framework for securing pods.

## Background

Pod Security Standards in Kubernetes define three policies:
- **Privileged**: Unrestricted policy
- **Baseline**: Minimally restrictive policy
- **Restricted**: Highly restricted policy for security-critical applications

For FedRAMP compliance, we should enforce at least Baseline, with Restricted recommended for sensitive workloads.

## Authoritative References

This exercise is based on the following authoritative sources:

- **NIST SP 800-53 Rev. 5**: 
  - SC-7 (Boundary Protection)
  - CM-7 (Least Functionality)
  - AC-6 (Least Privilege)

- **CIS Kubernetes Benchmark v1.6.1**:
  - Section 4.2: Pod Security Policies (now Pod Security Standards)
  - Control 4.2.1: Minimize the admission of privileged containers
  - Control 4.2.2: Minimize the admission of containers wishing to share the host process ID or IPC namespace
  - Control 4.2.3: Minimize the admission of containers wishing to share the host network namespace
  - Control 4.2.6: Minimize the admission of root containers
  - Control 4.2.7: Minimize the admission of containers with the NET_RAW capability
  - Control 4.2.8: Minimize the admission of containers with added capabilities

- **Kubernetes Pod Security Standards Documentation**:
  - [Official Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

- **CNCF Cloud Native Security Whitepaper**:
  - Section 4.1: Pod Security

For more detailed information, see `/root/authoritative-references.md` after completing this scenario.

## Task 1: Create a non-compliant deployment

Let's create a deployment with security issues:

```bash
cat << EOF > /root/non-compliant-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-pod
  namespace: fedramp-demo
spec:
  hostNetwork: true
  hostPID: true
  hostIPC: true
  containers:
  - name: non-compliant-container
    image: nginx
    securityContext:
      privileged: true
      allowPrivilegeEscalation: true
      capabilities:
        add: ["ALL"]
      runAsUser: 0
EOF

kubectl apply -f /root/non-compliant-pod.yaml
```{{exec}}

## Task 2: Audit the deployment for PSS compliance

Let's check our pod against Pod Security Standards:

```bash
kubectl get pod non-compliant-pod -n fedramp-demo -o yaml | grep -E "hostNetwork|hostPID|hostIPC|privileged|allowPrivilegeEscalation|runAsUser|capabilities"
```{{exec}}

This pod has multiple security issues that violate FedRAMP requirements:
1. **Host namespaces** (hostNetwork, hostPID, hostIPC): Violates isolation (SC-7)
2. **Privileged container**: Excessive privileges (AC-6)
3. **Allow privilege escalation**: Potential for privilege escalation (AC-6)
4. **Running as root**: Violates least privilege (AC-6)
5. **All capabilities**: Excessive system capabilities (CM-7)

## Task 3: Create a compliant pod definition

Now, let's create a FedRAMP-compliant pod:

```bash
cat << EOF > /root/compliant-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: fedramp-demo
spec:
  containers:
  - name: compliant-container
    image: nginx
    securityContext:
      privileged: false
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
      runAsUser: 1000
      runAsNonRoot: true
      readOnlyRootFilesystem: true
EOF

kubectl apply -f /root/compliant-pod.yaml
```{{exec}}

Let's examine the compliant pod:

```bash
kubectl get pod compliant-pod -n fedramp-demo -o yaml | grep -E "securityContext|privileged|allowPrivilegeEscalation|runAsUser|runAsNonRoot|readOnlyRootFilesystem|capabilities"
```{{exec}}

## Side-by-Side Compliance Comparison

Let's examine a side-by-side comparison of non-compliant vs. FedRAMP-compliant Pod configurations:

```bash
grep -A14 "Pod Security Examples" /root/compliance-examples.md
```{{exec}}

Notice the key differences:
- Non-compliant pods use host namespaces and run as privileged
- Non-compliant pods allow privilege escalation and run as root
- Compliant pods use restrictive security context settings
- Compliant pods run as non-root with minimal capabilities

To see the complete set of Pod Security compliance examples:

```bash
grep -A64 "Pod Security Examples" /root/compliance-examples.md
```{{exec}}

## Task 4: Apply Pod Security Standards

Kubernetes allows enforcing Pod Security Standards at the namespace level:

```bash
kubectl label --overwrite ns fedramp-demo pod-security.kubernetes.io/enforce=restricted
```{{exec}}

Now try to create another non-compliant pod:

```bash
kubectl apply -f /root/non-compliant-pod.yaml
```{{exec}}

Notice how the API server rejects the pod due to security violations.

## Real-World Case Study: Container Security Issues

Let's examine a real-world case study related to container security:

```bash
grep -A20 "Case Study 5: Kube-proxy" /root/kubernetes-security-case-studies.md
```{{exec}}

This case study illustrates how vulnerabilities in Kubernetes components can lead to privilege escalation. Such vulnerabilities could be mitigated by applying the Pod Security Standards we just learned about.

Let's look at another example related to API server vulnerabilities:

```bash
grep -A20 "Case Study 6: Kubernetes API Server" /root/kubernetes-security-case-studies.md
```{{exec}}

These incidents demonstrate why enforcing Pod Security Standards is essential for FedRAMP compliance. By implementing the restricted profile and keeping components updated, many of these vulnerabilities can be mitigated.

In the next step, we'll validate Network Policies and Security Context configurations.