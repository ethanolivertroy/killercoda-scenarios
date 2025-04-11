#!/bin/bash

# Check if our ValidatingAdmissionPolicies are created
if ! kubectl get validatingadmissionpolicies | grep -q "require-security-labels"; then
  echo "Required policy require-security-labels not found"
  exit 1
fi

# Check if our ValidatingAdmissionPolicyBindings are created
if ! kubectl get validatingadmissionpolicybindings | grep -q "require-security-labels-binding"; then
  echo "Required policy binding require-security-labels-binding not found"
  exit 1
fi

# Check that we have at least 2 policies
policy_count=$(kubectl get validatingadmissionpolicies | grep -v NAME | wc -l)
if [ "$policy_count" -lt 2 ]; then
  echo "Expected at least 2 ValidatingAdmissionPolicies, found only $policy_count"
  exit 1
fi

echo "Step 1 verification successful!"
exit 0