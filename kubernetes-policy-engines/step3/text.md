# Auditing and Documenting Policy Compliance

In this step, we will:
1. Create a comprehensive audit of our policy enforcement
2. Map our policies to specific FedRAMP controls
3. Generate compliance documentation for FedRAMP authorization
4. Create a policy audit tool for continuous monitoring

## Creating a Policy Audit

Let's begin by examining the current state of our policies and how they're enforcing FedRAMP controls:

```
# Check OPA Gatekeeper constraints
kubectl get constraints
```{{exec}}

```
# Check Kyverno policies
kubectl get cpol
```{{exec}}

## Mapping Policies to FedRAMP Controls

To demonstrate compliance with FedRAMP, we need to map our policies to specific NIST 800-53 controls. Let's examine our mapping document:

```
cat /root/nist-policy-controls.md
```{{exec}}

This document maps each of our policies to specific FedRAMP controls and explains how they support compliance.

## Policy Compliance Examples

Let's examine examples of compliant and non-compliant resources:

```
cat /root/policy-compliance-examples.md
```{{exec}}

These examples provide clear documentation of what constitutes compliance and can be used as part of your FedRAMP System Security Plan (SSP).

## Creating a Policy Audit Tool

Let's examine our audit tool that can be used to verify policy compliance:

```
cat /root/policy-audit-tool.sh
```{{exec}}

Now, let's make it executable and run it:

```
chmod +x /root/policy-audit-tool.sh
/root/policy-audit-tool.sh
```{{exec}}

This tool checks for:
1. Policy presence and enforcement
2. Current violations and audit results
3. FedRAMP control coverage

## Generating Compliance Evidence

For FedRAMP authorization, you'll need to generate evidence of policy enforcement. Let's create a sample report:

```
# Create a report directory
mkdir -p ~/fedramp-evidence/policy-enforcement

# Generate OPA Gatekeeper report
kubectl get constraint --all-namespaces -o yaml > ~/fedramp-evidence/policy-enforcement/gatekeeper-constraints.yaml

# Generate Kyverno report
kubectl get cpol --all-namespaces -o yaml > ~/fedramp-evidence/policy-enforcement/kyverno-policies.yaml
kubectl get policyreport --all-namespaces -o yaml > ~/fedramp-evidence/policy-enforcement/kyverno-policyreports.yaml

# Generate a summary report
cat << EOF > ~/fedramp-evidence/policy-enforcement/summary.md
# Kubernetes Policy Enforcement Summary

## Overview
This document summarizes the policy enforcement in place to support FedRAMP compliance in the Kubernetes environment.

## Policy Engines Implemented
1. OPA Gatekeeper
2. Kyverno

## Key Controls Enforced
1. Component Inventory Management (CM-8)
2. Least Privilege (AC-6)
3. Least Functionality (CM-7)
4. Resource Availability (SC-6)

## Implementation Details
- All workloads are validated against these policies at admission time
- Existing workloads are audited for compliance
- Continuous monitoring is in place to detect policy violations

## Evidence Files
- gatekeeper-constraints.yaml: Current OPA Gatekeeper constraints and status
- kyverno-policies.yaml: Current Kyverno policies in place
- kyverno-policyreports.yaml: Audit results from Kyverno policy enforcement

This evidence supports FedRAMP authorization by demonstrating automated enforcement of security controls.
EOF

# List the generated evidence
ls -la ~/fedramp-evidence/policy-enforcement/
```{{exec}}

## Best Practices for FedRAMP Compliance

When using policy engines for FedRAMP compliance, follow these best practices:

1. **Document Policy Intent**: For each policy, document which FedRAMP control it supports
2. **Track Policy Coverage**: Ensure all applicable FedRAMP controls have corresponding policies
3. **Continuous Validation**: Implement continuous monitoring of policy enforcement
4. **Regular Audits**: Periodically review policy reports to identify and address issues
5. **Evidence Collection**: Automatically collect policy reports for FedRAMP audit evidence
6. **Exception Management**: Document any policy exceptions and their justifications
7. **Change Management**: Update policies when FedRAMP requirements or the system changes
8. **Policy Testing**: Test policies thoroughly in non-production environments first

## Implementing Continuous Compliance Monitoring

Let's implement a simple cron job that runs our policy audit tool regularly:

```
cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: policy-compliance-audit
  namespace: default
spec:
  schedule: "0 * * * *"  # Hourly
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: default
          containers:
          - name: policy-audit
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              echo "Running policy compliance audit at $(date)"
              kubectl get constraints -o custom-columns=NAME:.metadata.name,ENFORCED:.spec.enforcementAction,VIOLATIONS:.status.totalViolations
              kubectl get cpol -o custom-columns=NAME:.metadata.name,ENFORCED:.spec.validationFailureAction,BACKGROUND:.spec.background
              echo "Audit completed"
            resources:
              limits:
                cpu: "100m"
                memory: "128Mi"
              requests:
                cpu: "50m"
                memory: "64Mi"
          restartPolicy: OnFailure
EOF
```{{exec}}

## Conclusion

In this step, we've:
1. Created a comprehensive audit of our policy enforcement
2. Mapped our policies to specific FedRAMP controls
3. Generated compliance documentation for FedRAMP authorization
4. Created tools for continuous monitoring

These activities support a robust policy-as-code implementation that helps demonstrate FedRAMP compliance for your Kubernetes environment. By automating policy enforcement, you can provide continuous assurance that your system meets security requirements.