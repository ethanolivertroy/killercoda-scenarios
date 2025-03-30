# Auditing Kubernetes RBAC Configuration

One of the key FedRAMP requirements is ensuring proper access control and privilege management (NIST 800-53 AC-2, AC-3, AC-6). In Kubernetes, this is primarily managed through Role-Based Access Control (RBAC).

## Background

RBAC in Kubernetes consists of:
- **Roles/ClusterRoles**: Define permissions on resources
- **RoleBindings/ClusterRoleBindings**: Associate roles with users, groups, or service accounts

For FedRAMP compliance, we must ensure the principle of least privilege is followed.

## Authoritative References

This exercise is based on the following authoritative sources:

- **NIST SP 800-53 Rev. 5**: 
  - AC-2 (Account Management)
  - AC-3 (Access Enforcement)
  - AC-6 (Least Privilege)

- **CIS Kubernetes Benchmark v1.6.1**:
  - Section 3.2: RBAC and Service Accounts
  - Control 3.2.1: Ensure that a minimal set of users/groups/service accounts have wildcard access to Cluster Roles/Roles

- **Kubernetes RBAC Documentation**:
  - [Official Kubernetes RBAC Guide](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

For more detailed information, see `/root/authoritative-references.md` after completing this scenario.

## Task 1: Identify overly permissive roles

First, let's examine the ClusterRoles in the cluster:

```bash
kubectl get clusterroles
```{{exec}}

Now, let's look for roles with wildcards or excessive permissions:

```bash
kubectl get clusterroles -o yaml | grep -E "resources:|verbs:" | grep -E "\*"
```{{exec}}

## Task 2: Audit service account permissions

Let's create a simple script to check service account bindings:

```bash
cat << EOF > /root/check-sa-permissions.sh
#!/bin/bash
for ns in \$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')
do
  echo "Namespace: \$ns"
  for sa in \$(kubectl get sa -n \$ns -o jsonpath='{.items[*].metadata.name}')
  do
    echo "  ServiceAccount: \$sa"
    kubectl get rolebinding,clusterrolebinding -A -o json | jq '.items[] | select(.subjects[]?.kind=="ServiceAccount" and .subjects[]?.name=="\$sa" and .subjects[]?.namespace=="\$ns") | "\(.roleRef.kind) \(.roleRef.name)"' 2>/dev/null
  done
done
EOF

chmod +x /root/check-sa-permissions.sh
```{{exec}}

Run the script to audit service account permissions:

```bash
/root/check-sa-permissions.sh
```{{exec}}

## Task 3: Identify non-compliant RBAC configurations

For FedRAMP compliance, we need to remediate any overly permissive roles. 

Let's create a non-compliant role for demonstration:

```bash
kubectl create namespace fedramp-demo
kubectl create role overly-permissive --namespace fedramp-demo --verb="*" --resource="*"
kubectl create serviceaccount demo-sa --namespace fedramp-demo
kubectl create rolebinding demo-binding --namespace fedramp-demo --role=overly-permissive --serviceaccount=fedramp-demo:demo-sa
```{{exec}}

Now, examine this configuration:

```bash
kubectl get role overly-permissive -n fedramp-demo -o yaml
```{{exec}}

According to FedRAMP compliance based on NIST 800-53 controls, this role violates the principle of least privilege (AC-6).

## Side-by-Side Compliance Comparison

Let's examine a side-by-side comparison of non-compliant vs. FedRAMP-compliant RBAC configurations:

```bash
grep -A14 "RBAC Examples" /root/compliance-examples.md
```{{exec}}

Notice the key differences:
- Non-compliant roles use wildcards (`*`) for API groups, resources, and verbs
- Compliant roles specify exact API groups, resources, and verbs
- Compliant roles may further restrict by resource names

To fix the issues with our demo role, you would need to:
1. Define specific permissions required for the service account
2. Remove wildcard permissions
3. Apply granular access control

To see the complete set of RBAC compliance examples:

```bash
grep -A45 "RBAC Examples" /root/compliance-examples.md
```{{exec}}

## Real-World Case Study: RBAC Misconfiguration

Let's look at a real-world case study related to RBAC issues:

```bash
grep -A20 "Case Study 1: Tesla" /root/kubernetes-security-case-studies.md
```{{exec}}

This case study demonstrates how inadequate access controls for Kubernetes resources can lead to security breaches. The Tesla incident could have been prevented with proper RBAC implementation and adherence to FedRAMP AC controls.

You can also explore how excessive permissions were exploited in the Shopify incident:

```bash
grep -A20 "Case Study 3: Shopify" /root/kubernetes-security-case-studies.md
```{{exec}}

These incidents emphasize why proper RBAC configuration according to FedRAMP requirements is critical for protecting Kubernetes environments.

In the next step, we'll assess Pod Security Standards compliance.