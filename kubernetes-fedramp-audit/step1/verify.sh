#!/bin/bash

# Check if the user has created the demo namespace and resources
if kubectl get namespace fedramp-demo &>/dev/null; then
  if kubectl get role overly-permissive -n fedramp-demo &>/dev/null; then
    if kubectl get sa demo-sa -n fedramp-demo &>/dev/null; then
      if kubectl get rolebinding demo-binding -n fedramp-demo &>/dev/null; then
        echo "Great! You've successfully created the demo resources for RBAC auditing."
        exit 0
      fi
    fi
  fi
fi

echo "You need to create all the required resources for RBAC auditing as described in the task."
exit 1