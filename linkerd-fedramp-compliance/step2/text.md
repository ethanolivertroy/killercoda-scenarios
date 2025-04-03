# Implementing mTLS and Security Policies

In this step, we'll focus on implementing and validating Linkerd's mTLS capabilities and security policies. These features are critical for meeting FedRAMP requirements around secure communications and access control.

## Background: Linkerd Security Features

Linkerd's security model addresses several key FedRAMP requirements:

- **Automatic mTLS**: All service-to-service communication is automatically encrypted (SC-8)
- **Service identity**: Each service has a cryptographic identity for authentication (IA-2)
- **Traffic policy enforcement**: Access controls can be enforced based on service identity (AC-3)
- **Certificate management**: Automatic rotation of certificates with short lifetimes (IA-5)

## Task 1: Deploy Sample Microservices

First, let's create a namespace for our demo applications and configure it for automatic Linkerd injection:

```bash
# Create a namespace for our applications
kubectl create namespace secure-apps

# Annotate the namespace for Linkerd injection
kubectl annotate namespace secure-apps linkerd.io/inject=enabled

# Check that the namespace exists and is annotated properly
kubectl get namespace secure-apps --show-labels
kubectl get namespace secure-apps -o jsonpath='{.metadata.annotations.linkerd\.io/inject}'
```{{exec}}

Now let's deploy our sample front-end and back-end microservices:

```bash
# Deploy sample applications with service accounts, deployments, and services
cat << EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend
  namespace: secure-apps
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend
  namespace: secure-apps
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: secure-apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      annotations:
        linkerd.io/inject: enabled
      labels:
        app: frontend
    spec:
      serviceAccountName: frontend
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: secure-apps
spec:
  ports:
  - port: 80
    targetPort: 80
    name: http
  selector:
    app: frontend
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: secure-apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      annotations:
        linkerd.io/inject: enabled
      labels:
        app: backend
    spec:
      serviceAccountName: backend
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: secure-apps
spec:
  ports:
  - port: 80
    targetPort: 80
    name: http
  selector:
    app: backend
EOF

# Check if the deployments and services were created
kubectl get deployments,services,serviceaccounts -n secure-apps
```{{exec}}

Now, let's create a ConfigMap with HTML content for our backend service and deploy a backend service with the ConfigMap mounted:

```bash
# Create a ConfigMap with content for the backend service and update the backend deployment
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-content
  namespace: secure-apps
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Backend Service</title></head>
    <body>
      <h1>Hello from Backend Service</h1>
      <p>This is a test page from the backend service.</p>
    </body>
    </html>
EOF

# Update the backend deployment to use the ConfigMap
kubectl patch deployment backend -n secure-apps --type=json -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value": [{"name": "content", "mountPath": "/usr/share/nginx/html"}]},
  {"op": "add", "path": "/spec/template/spec/volumes", "value": [{"name": "content", "configMap": {"name": "backend-content"}}]}
]'

# Make sure both deployments are fully ready
kubectl wait --for=condition=available deployment/frontend -n secure-apps --timeout=90s
kubectl wait --for=condition=available deployment/backend -n secure-apps --timeout=90s

# Check that pods are running with Linkerd proxies injected
kubectl get pods -n secure-apps
```{{exec}}

## Task 2: Verify mTLS Encryption

Let's verify that our pods have been properly injected with the Linkerd proxy and that mTLS is enabled:

```bash
# Check that the pods have been injected with the Linkerd proxy (should show 2/2 containers)
kubectl get pods -n secure-apps

# Verify which containers are in the pods
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')
echo "Containers in frontend pod:"
kubectl get pod $FRONTEND_POD -n secure-apps -o jsonpath='{.spec.containers[*].name}'
echo

# Verify that mTLS is enabled for our services (check for √ in the mTLS column)
linkerd viz edges -n secure-apps deployment
linkerd viz stat -n secure-apps deployment
```{{exec}}

This confirms that Linkerd has established mTLS between our services, meeting SC-8 requirements for encrypted communications.

## Task 3: Implement Authorization Policies

Now let's verify the policy capabilities in our Linkerd installation and create authorization policies:

```bash
# Check for policy-related CRDs
kubectl get crds | grep linkerd.io

# Check API resources
kubectl api-resources | grep linkerd.io

# If needed, install curl in the frontend pod to test connectivity
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- apk add --no-cache curl

# Test baseline connectivity before applying policies
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s http://backend.secure-apps.svc.cluster.local
```{{exec}}

Let's create a Server resource and ServerAuthorization policy to restrict access to the backend service:

```bash
# Create Server and ServerAuthorization resources using the recommended API versions
# First, create the Server
cat << EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1beta3
kind: Server
metadata:
  name: backend-server
  namespace: secure-apps
spec:
  podSelector:
    matchLabels:
      app: backend
  port: 80
  proxyProtocol: HTTP/1
EOF

# Check which API version of ServerAuthorization is supported
echo "Checking supported ServerAuthorization API version..."
if kubectl api-resources | grep -q serverauthorizations.policy.linkerd.io ; then
  echo "Using ServerAuthorization v1beta1 API format"
  cat << EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  name: backend-server-auth
  namespace: secure-apps
spec:
  server: backend-server
  client:
    # Only allow frontend service account
    unauthenticated: false
    meshTLS:
      serviceAccounts:
        - name: frontend
          namespace: secure-apps
EOF
else
  echo "Using older ServerAuthorization API format"
  cat << EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1alpha1
kind: ServerAuthorization
metadata:
  name: backend-server-auth
  namespace: secure-apps
spec:
  server: backend-server
  client:
    # Only allow frontend service account
    unauthenticated: false
    meshTLS:
      serviceAccounts:
        - name: frontend
          namespace: secure-apps
EOF
fi
```{{exec}}

Verify that our Server and ServerAuthorization resources were created:

```bash
# Check if the resources were created
kubectl get server -n secure-apps
kubectl get serverauthorization -n secure-apps

# Describe the Server
kubectl describe server backend-server -n secure-apps

# Describe the ServerAuthorization
kubectl describe serverauthorization backend-server-auth -n secure-apps
```{{exec}}

## Task 4: Test Authorization Policies

Let's create a test pod and verify that unauthorized access is denied:

```bash
# Create a test pod for validation
kubectl run test-pod --image=nginx:alpine -n secure-apps
kubectl wait --for=condition=ready pod/test-pod -n secure-apps --timeout=60s

# Annotate the test pod to be added to the mesh
kubectl annotate pod test-pod -n secure-apps linkerd.io/inject=enabled

# Delete and recreate the pod to apply the annotation
kubectl delete pod test-pod -n secure-apps
kubectl run test-pod --image=nginx:alpine -n secure-apps
kubectl wait --for=condition=ready pod/test-pod -n secure-apps --timeout=60s

# Install curl in the test pod
kubectl exec -it test-pod -n secure-apps -c nginx -- apk add --no-cache curl

# Try to access the backend service from the test pod (should fail)
echo "Testing unauthorized access from test-pod (should fail):"
kubectl exec -it test-pod -n secure-apps -c nginx -- curl -s --max-time 5 http://backend.secure-apps.svc.cluster.local || echo "Access denied as expected"
```{{exec}}

Now, let's verify that our frontend pod (which is authorized) can access the backend service:

```bash
# Get frontend pod name
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Try to access the backend service from the frontend pod (should succeed)
echo "Testing authorized access from frontend pod (should succeed):"
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s http://backend.secure-apps.svc.cluster.local
```{{exec}}

## Task 5: Verify FedRAMP Security Controls

Let's validate our implementation against key FedRAMP security controls:

```bash
# View the mTLS status for connections in the secure-apps namespace
linkerd viz edges deployment -n secure-apps

# Check proxy metrics and certificates
linkerd viz stat -n secure-apps deployment

# Check if authorization is working by examining tap data
linkerd viz tap deployment/frontend -n secure-apps --to deployment/backend -n secure-apps --path / -o wide
```{{exec}}

## Task 6: Document FedRAMP Controls

Our Linkerd implementation addresses key FedRAMP requirements from NIST SP 800-53 Rev 5:

### Primary Security Controls

- **SC-8 (Transmission Confidentiality)**: Confirmed mTLS encryption between all services
- **SC-13 (Cryptographic Protection)**: Linkerd uses TLS 1.3 with strong algorithms
- **SC-23 (Session Authenticity)**: Verified mutual authentication via mTLS
- **AC-3 (Access Enforcement)**: Server authorization policies restrict access based on identity
- **AC-4 (Information Flow Enforcement)**: Implemented control of service-to-service communication
- **IA-2 (Identification and Authentication)**: Each service has a SPIFFE identity
- **IA-5 (Authenticator Management)**: Certificates automatically rotate with short lifetimes

### Implementation Verification

1. **Policy Enforcement**: We confirmed unauthorized pods cannot access protected services
2. **Identity Verification**: Services establish secure connections using unique identities
3. **Communication Security**: All traffic between services is encrypted via mTLS
4. **Observability**: Metrics capture security events for auditing

In the next step, we'll focus on auditing our service mesh and generating compliance evidence.