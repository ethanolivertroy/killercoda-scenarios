# Implementing mTLS and Security Policies

In this step, we'll focus on implementing and validating Linkerd's mTLS capabilities and security policies. These features are critical for meeting FedRAMP requirements around secure communications and access control.

## Background: Linkerd Security Features

Linkerd's security model addresses several key FedRAMP requirements:

- **Automatic mTLS**: All service-to-service communication is automatically encrypted (SC-8)
- **Service identity**: Each service has a cryptographic identity for authentication (IA-2)
- **Traffic policy enforcement**: Access controls can be enforced based on service identity (AC-3)
- **Certificate management**: Automatic rotation of certificates with short lifetimes (IA-5)

## Task 1: Deploy Sample Microservices

### Task 1a: Create Namespace and Prepare Environment

Let's create a namespace for our demo applications and configure it for automatic Linkerd injection:

```bash
# Create a namespace for our applications
kubectl create namespace secure-apps

# Annotate the namespace for Linkerd injection
kubectl annotate namespace secure-apps linkerd.io/inject=enabled
```{{exec}}

### Task 1b: Deploy Microservice Components

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
  selector:
    app: backend
EOF
```{{exec}}

### Task 1c: Create ConfigMap for Backend Content

Let's create a ConfigMap with some HTML content for our backend service to serve and restart the deployment to apply the changes:

```bash
# Create a ConfigMap with content for the backend service
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

# Restart the deployment to apply changes
kubectl rollout restart deployment backend -n secure-apps

# Wait for the deployment to finish restarting
kubectl rollout status deployment backend -n secure-apps
```{{exec}}

### Task 1d: Wait for Linkerd Injection and Pod Readiness

Now we need to wait for Linkerd to inject its proxies and for the pods to become ready:

```bash
# Check initial pod status
echo "Checking initial pod status..."
kubectl get pods -n secure-apps

# Wait for Linkerd to inject proxies and for pods to start
echo "Waiting for Linkerd to inject proxies and for pods to start..."
sleep 30
kubectl get pods -n secure-apps

# Wait for pods to become fully ready
echo "Waiting for pods to be fully ready..."
kubectl wait --for=condition=ready pod --all -n secure-apps --timeout=120s
```{{exec}}

## Task 2: Verify mTLS Encryption

### Task 2a: Check Proxy Injection

First, let's verify that our pods have been properly injected with the Linkerd proxy. We'll check the container count (should be 2 - the app container and the linkerd-proxy) and the READY status:

```bash
# Check that the pods have been injected with the Linkerd proxy
kubectl get pods -n secure-apps
kubectl get pods -n secure-apps -o jsonpath='{.items[*].spec.containers[*].name}' | tr ' ' '\n' | grep linkerd-proxy
```{{exec}}

### Task 2b: Verify mTLS Connections

Now, let's confirm that mTLS is properly enabled between our services:

```bash
# Verify that mTLS is enabled for our services (check for √ in the SECURED column)
linkerd viz edges -n secure-apps deployment

# Check the detailed traffic statistics
linkerd viz stat -n secure-apps deployment
```{{exec}}

This verification confirms that Linkerd has established mTLS between our services, meeting SC-8 requirements for encrypted communications.

## Task 3: Implement Authorization Policies

### Task 3a: Verify Policy API Support

Let's check what policy-related capabilities are available in our Linkerd installation:

```bash
# Check for policy-related CRDs
kubectl get crds | grep linkerd.io

# Check API resources
kubectl api-resources | grep linkerd.io

# Check the Linkerd version
linkerd version
```{{exec}}

### Task 3b: Create Server and Authorization Policy

Now let's create a Server resource and ServerAuthorization policy to restrict access to the backend service:

```bash
# Create Server and ServerAuthorization resources
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
---
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  name: backend-server-auth
  namespace: secure-apps
spec:
  server: backend-server
  client:
    unauthenticated: false
    meshTLS:
      serviceAccounts:
        - name: frontend
          namespace: secure-apps
EOF
```{{exec}}

### Task 3c: Create Test Pod for Access Testing

Let's create a test pod to verify that unauthorized access is denied:

```bash
# Create a test pod for validation
kubectl run test-pod --image=nginx:alpine -n secure-apps
kubectl wait --for=condition=ready pod/test-pod -n secure-apps --timeout=60s

# Annotate the test pod to be added to the mesh
kubectl annotate pod test-pod -n secure-apps linkerd.io/inject=enabled

# Restart the pod to apply the annotation
kubectl delete pod test-pod -n secure-apps
kubectl run test-pod --image=nginx:alpine -n secure-apps
kubectl wait --for=condition=ready pod/test-pod -n secure-apps --timeout=60s

# Install curl in the test pod for testing
kubectl exec -it test-pod -n secure-apps -c test-pod -- apk add --no-cache curl
```{{exec}}

### Task 3d: Test Unauthorized Access

Let's verify that unauthorized pods cannot access the backend service:

```bash
# Try to access the backend service from the test pod
# This should fail because test-pod is not authorized
kubectl exec -it test-pod -n secure-apps -c test-pod -- curl -s http://backend.secure-apps.svc.cluster.local --max-time 5 || echo "Access denied as expected"
```{{exec}}

### Task 3e: Test Authorized Access

Now let's verify that the frontend pod (which is authorized) can access the backend service:

```bash
# Get frontend pod name
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Install curl in the frontend pod
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- apk add --no-cache curl

# Try to access the backend service from the frontend pod (should be allowed)
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s http://backend.secure-apps.svc.cluster.local
```{{exec}}

## Task 4: Validate FedRAMP Security Requirements

### Task 4a: Verify mTLS Connection Details

Let's examine the mTLS connections in more detail to validate FedRAMP requirements:

```bash
# View the mTLS status for connections in the secure-apps namespace
linkerd viz edges deployment -n secure-apps

# Try a direct invocation with verbose output to see mTLS details
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -sv http://backend.secure-apps.svc.cluster.local
```{{exec}}

### Task 4b: Review Certificate Configuration

Let's examine the certificate configuration for FedRAMP validation:

```bash
# Check proxy metrics and certificates
linkerd viz stat -n secure-apps deployment/frontend

# View information about the proxy identity and configuration
kubectl get pod $FRONTEND_POD -n secure-apps -o yaml | grep -A5 linkerd.io/proxy-version

# Check linkerd identity settings
kubectl get pod $FRONTEND_POD -n secure-apps -o yaml | grep linkerd | grep identity
```{{exec}}

## Task 5: Document FedRAMP Controls

Here's how our Linkerd implementation addresses key FedRAMP requirements from NIST SP 800-53 Rev 5:

### Primary Security Controls Directly Implemented

#### Transmission Security and Cryptography
- **SC-8**: Our demonstration confirms mTLS encryption between all services
- **SC-13**: Linkerd implements TLS 1.3 with strong ECDSA P-256 algorithms
- **SC-23**: We've verified mutual authentication between services via mTLS

#### Access Management
- **AC-3**: Our server authorization policies successfully restricted access based on identity
- **AC-4**: We've implemented information flow control between services

#### Service Identity
- **IA-2**: Each service received a cryptographically verifiable SPIFFE identity
- **IA-5**: Certificate rotation is configured with appropriate short lifetimes

### Supporting Security Capabilities

These controls are partially addressed and require integration with additional systems:

#### Extended Protection
- **SC-17**: Linkerd's PKI for service certificates provides workload identity
- **AC-6**: Our authorization policies implement least privilege for service communication

#### Monitoring and Audit
- **AU-2/AU-3**: Access logs capture detailed information, but require collection infrastructure
- **AU-12**: Metrics and logs are generated but need external storage and analysis
- **SI-4**: The service mesh provides golden metrics but requires dashboarding
- **SI-7**: Data integrity in transit is protected via cryptographic verification

### Implementation Verification

Our demonstration has validated the following security aspects:

1. **Policy Enforcement**: We confirmed that unauthorized pods cannot access protected services
2. **Identity Verification**: Services establish secure connections using unique identities
3. **Communication Security**: All traffic between services is encrypted via mTLS
4. **Observability**: Metrics capture security-relevant events for auditing

To complete a comprehensive FedRAMP implementation, you would need to integrate Linkerd with:
- External logging and SIEM systems
- Long-term metrics storage
- Certificate management systems
- Alerting infrastructure

In the next step, we'll focus on auditing our service mesh and generating compliance evidence.