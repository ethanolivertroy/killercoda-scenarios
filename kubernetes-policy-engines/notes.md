# Kubernetes Policy Engines Scenario - Debugging Notes

## Current Status

We've created a comprehensive Kubernetes Policy Engines scenario for FedRAMP compliance, but there's an issue with the step1 verification. The validation check is failing despite all the policy components being correctly deployed and working.

## What's Working

1. **OPA Gatekeeper Installation**:
   - Successfully installed with `kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml`
   - Pods are running (2 of 3 controller pods running, audit pod running)
   - 1 pod is in Pending state due to resource constraints (expected in limited environments)

2. **Constraint Templates**:
   - Created with `kubectl apply -f /root/opa-constraints.yaml`
   - 4 templates created: k8srequiredlabels, k8sblockprivilegedcontainers, k8sallowedrepos, k8srequiredresources

3. **Constraints**:
   - Created with properly formatted manifest
   - All 4 constraints are present when running `kubectl get constraints`
   - We can view the details with `kubectl get k8srequiredlabels.constraints.gatekeeper.sh/require-security-labels -o yaml`

4. **Policy Testing**:
   - Non-compliant pod was correctly blocked with the expected validation errors
   - Compliant pod was successfully created

## Verification Issue

The verification script (`step1/verify.sh`) checks for:
1. OPA Gatekeeper namespace existence (passing)
2. Running pods in gatekeeper-system namespace (passing) 
3. Constraint templates existence (might be failing due to case sensitivity)
4. Constraints existence (might be failing due to how we query for constraints)

We've modified the verification script to use more specific constraint lookup:
```bash
# Original
if ! kubectl get constraints | grep -q "require-security-labels"; then
  echo "Required constraints not found"
  exit 1
fi

# Modified to be more specific
if ! kubectl get k8srequiredlabels.constraints.gatekeeper.sh require-security-labels &>/dev/null; then
  echo "Required constraint require-security-labels not found"
  exit 1
fi
```

## Debugging Tools

We've created a debug script `debug-verify.sh` that performs each verification check individually and provides detailed output. This should help identify exactly which check is failing.

## Next Steps

When resuming work:

1. Run `./debug-verify.sh` to identify the specific failing check
2. Check the case sensitivity of template names (k8srequiredlabels vs K8sRequiredLabels)
3. Consider other potential issues:
   - Timing issues: Gatekeeper might be slow to reconcile constraints
   - Resource issues: The environment might not have enough resources
   - Command structure: Ensure commands match exactly what Killercoda environment expects

4. If needed, simplify the verification script to focus on the most essential checks
5. Test any changes thoroughly before committing

## Recent Changes

- Modified step1/verify.sh to use more specific constraint lookup
- Created debugging script to identify verification issues
- Updated all command blocks to use Killercoda's clickable execution format `{{exec}}`
- Fixed constraint query to use the full resource name

## File Structure

The scenario consists of:
- index.json: The main configuration file
- intro.md: Introduction to Kubernetes Policy Engines
- step1/: OPA Gatekeeper implementation
- step2/: Kyverno implementation
- step3/: Auditing and documenting compliance
- assets/: Supporting files (constraints, policies, audit tools)
- finish.md: Conclusion and next steps