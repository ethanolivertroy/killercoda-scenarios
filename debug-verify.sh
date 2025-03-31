#\!/bin/bash

# Debugging script to help identify verification issues

echo "===== Environment Verification ====="
echo "Working Directory:"
pwd
echo

echo "===== OPA Gatekeeper Namespace ====="
kubectl get ns gatekeeper-system
if \! kubectl get ns gatekeeper-system &>/dev/null; then
  echo "[FAIL] OPA Gatekeeper namespace not found"
else
  echo "[PASS] OPA Gatekeeper namespace found"
fi
echo

echo "===== OPA Gatekeeper Pods ====="
kubectl get pods -n gatekeeper-system
if \! kubectl get pods -n gatekeeper-system | grep -q "Running"; then
  echo "[FAIL] OPA Gatekeeper pods are not running"
else
  echo "[PASS] OPA Gatekeeper pods are running"
fi
echo

echo "===== Constraint Templates ====="
kubectl get constrainttemplates
if \! kubectl get constrainttemplates | grep -q "k8srequiredlabels"; then
  echo "[FAIL] Required constraint templates not found"
else
  echo "[PASS] Required constraint templates found"
fi
echo

echo "===== Constraints ====="
kubectl get constraints
echo

echo "===== Specific Constraint Lookup ====="
kubectl get k8srequiredlabels.constraints.gatekeeper.sh require-security-labels 2>/dev/null
if \! kubectl get k8srequiredlabels.constraints.gatekeeper.sh require-security-labels &>/dev/null; then
  echo "[FAIL] Required constraint require-security-labels not found"
else
  echo "[PASS] Required constraint require-security-labels found"
fi
echo

echo "===== Compliant Pod Check ====="
kubectl get pod compliant-pod 2>/dev/null
if \! kubectl get pod compliant-pod &>/dev/null; then
  echo "[FAIL] Compliant pod not found"
else
  echo "[PASS] Compliant pod found"
fi
