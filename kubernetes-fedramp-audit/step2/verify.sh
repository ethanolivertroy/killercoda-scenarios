#!/bin/bash

# Check if the user has created both pods
if kubectl get pod compliant-pod -n fedramp-demo &>/dev/null; then
  # Check if the namespace has the Pod Security Standard label
  if kubectl get ns fedramp-demo --show-labels | grep -q "pod-security.kubernetes.io/enforce=restricted"; then
    echo "Great! You've successfully configured Pod Security Standards."
    exit 0
  else
    echo "You need to apply the Pod Security Standard label to the namespace."
    exit 1
  fi
else
  echo "You need to create the compliant pod as described in the task."
  exit 1
fi