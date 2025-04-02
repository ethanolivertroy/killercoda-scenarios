#!/bin/bash

# Check that the secure-apps namespace exists and is annotated for Linkerd
if kubectl get namespace secure-apps &>/dev/null && kubectl get namespace secure-apps -o jsonpath='{.metadata.annotations.linkerd\.io/inject}' | grep -q enabled; then
  # Check that the services are deployed and running
  if kubectl get pods -n secure-apps -l app=frontend &>/dev/null && \
     kubectl get pods -n secure-apps -l app=backend &>/dev/null && \
     kubectl get pods -n secure-apps -o jsonpath='{.items[?(@.metadata.labels.app=="frontend")].status.phase}' | grep -q Running && \
     kubectl get pods -n secure-apps -o jsonpath='{.items[?(@.metadata.labels.app=="backend")].status.phase}' | grep -q Running; then
    
    # Check that the backend-content ConfigMap exists
    if kubectl get configmap backend-content -n secure-apps &>/dev/null; then
      
      # Check that the server and authorization policy exists
      # Use multiple API versions to be more flexible
      if (kubectl get server.policy.linkerd.io backend-server -n secure-apps &>/dev/null || kubectl get server backend-server -n secure-apps &>/dev/null) && \
         (kubectl get serverauthorization.policy.linkerd.io backend-server-auth -n secure-apps &>/dev/null || kubectl get serverauthorization backend-server-auth -n secure-apps &>/dev/null); then
        
        # Check that the HTTP route exists using different methods
        if kubectl get httproute.policy.linkerd.io backend-route -n secure-apps &>/dev/null || kubectl get httproute backend-route -n secure-apps &>/dev/null; then
          
          # Get frontend pod name
          FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')
          
          # Try to access the backend service from the frontend pod - should return content
          if kubectl exec $FRONTEND_POD -n secure-apps -c nginx -- curl -s -o /dev/null -w "%{http_code}" http://backend.secure-apps.svc.cluster.local | grep -q "200"; then
            echo "Great! You've successfully implemented and tested mTLS and security policies in your Linkerd mesh."
            exit 0
          else
            echo "The backend service is not responding correctly. Make sure the ConfigMap is mounted properly."
            exit 1
          fi
        else
          echo "HTTP route is missing. Please create the HTTP route for the backend service."
          exit 1
        fi
      else
        echo "Server or ServerAuthorization policies are missing. Please create both resources."
        exit 1
      fi
    else
      echo "Backend content ConfigMap is missing. Please create the ConfigMap for the backend service."
      exit 1
    fi
  else
    echo "Frontend or backend services are not running properly. Please check their deployment."
    exit 1
  fi
else
  echo "The secure-apps namespace is not properly configured. Please create and annotate it."
  exit 1
fi