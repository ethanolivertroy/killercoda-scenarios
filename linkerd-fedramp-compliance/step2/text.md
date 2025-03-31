# Implementing mTLS and Security Policies

In this step, we'll focus on implementing and validating Linkerd's mTLS capabilities and security policies. These features are critical for meeting FedRAMP requirements around secure communications and access control.

## Background: Linkerd Security Features

Linkerd's security model addresses several key FedRAMP requirements:

- **Automatic mTLS**: All service-to-service communication is automatically encrypted (SC-8)
- **Identity-based security**: Each service has a cryptographic identity for authentication (IA-3)
- **Traffic policy enforcement**: Access controls can be enforced based on service identity (AC-3)
- **Certificate management**: Automatic rotation of certificates with short lifetimes (IA-5)

## Task 1: Deploy Sample Microservices

Let's deploy sample microservices to demonstrate Linkerd's security capabilities:

```bash
# Create a namespace for our applications
kubectl create namespace secure-apps

# Annotate the namespace for Linkerd injection
kubectl annotate namespace secure-apps linkerd.io/inject=enabled

# Deploy sample applications
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

# Check the pods status and wait for them to be ready
# (This might take 1-2 minutes as Linkerd injects the proxy sidecars)
echo "Checking pod status. Initial creation may show 'no resources found' - this is normal."
kubectl get pods -n secure-apps

echo "Waiting 30 seconds for Linkerd to inject proxies and for pods to start..."
sleep 30
kubectl get pods -n secure-apps

# Now the pods should be visible, but might still be in "ContainerCreating" state
# Wait for them to be fully ready
echo "Waiting for pods to be fully ready..."
kubectl wait --for=condition=ready pod --all -n secure-apps --timeout=120s
```{{exec}}

## Task 2: Verify mTLS Encryption

Linkerd automatically establishes mTLS between meshed services. Let's verify this:

```bash
# Check that the pods have been injected with the Linkerd proxy
kubectl get pods -n secure-apps -o jsonpath='{.items[*].metadata.name}' | xargs -n1 kubectl -n secure-apps get pod -o yaml | grep linkerd.io/proxy-status

# Verify that mTLS is enabled for our services
linkerd viz edges -n secure-apps deployment

# Check the detailed stats
linkerd viz stat -n secure-apps deployment
```{{exec}}

This verifies that Linkerd has established mTLS between our services, meeting SC-8 requirements for encrypted communications.

## Task 3: Implement Authorization Policies

FedRAMP requires fine-grained access control (AC-3, AC-4). Linkerd supports this through authorization policies:

```bash
# The policy controller is now included in the default installation
# Check that policy components are installed
kubectl get deploy -n linkerd | grep policy

# Create a server authorization policy to restrict access to the backend service
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
apiVersion: policy.linkerd.io/v1beta3
kind: ServerAuthorization
metadata:
  name: backend-server-auth
  namespace: secure-apps
spec:
  server: backend-server
  client:
    # Only allow the frontend service to access the backend service
    unauthenticated: false
    meshTLS:
      serviceAccounts:
        - name: frontend
          namespace: secure-apps
EOF

# Create a test pod to verify that unauthorized access is denied
kubectl run test-pod --image=nginx:alpine -n secure-apps
kubectl wait --for=condition=ready pod/test-pod -n secure-apps --timeout=60s

# Annotate the test pod to be added to the mesh
kubectl annotate pod test-pod -n secure-apps linkerd.io/inject=enabled

# Restart the pod to apply the annotation
kubectl delete pod test-pod -n secure-apps
kubectl run test-pod --image=nginx:alpine -n secure-apps
kubectl wait --for=condition=ready pod/test-pod -n secure-apps --timeout=60s

# Install curl in the test pod since wget isn't available
kubectl exec -it test-pod -n secure-apps -c test-pod -- apk add --no-cache curl

# Try to access the backend service from the test pod (should be denied)
kubectl exec -it test-pod -n secure-apps -c test-pod -- curl -s http://backend.secure-apps.svc.cluster.local --max-time 5 || echo "Access denied as expected"

# Install curl in the frontend pod
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- apk add --no-cache curl

# Try to access the backend service from the frontend pod (should be allowed)
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s http://backend.secure-apps.svc.cluster.local
```{{exec}}

## Task 4: Implement MTLS and Certificate Validation

Let's examine how Linkerd manages certificates, which is essential for FedRAMP's cryptographic requirements (SC-13, IA-5):

```bash
# Check certificate information in the Linkerd data plane
linkerd diagnostics proxy -n secure-apps deployment/frontend --tap

# View the certificate details
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $FRONTEND_POD -n secure-apps -c linkerd-proxy -- env | grep LINKERD

# Check the identity certificate expiration
kubectl exec -it $FRONTEND_POD -n secure-apps -c linkerd-proxy -- ls -la /var/run/linkerd/identity/
```{{exec}}

## Task 5: Security Policy Testing and Validation

Let's implement a more complex policy scenario to validate Linkerd's security capabilities:

```bash
# For this version of Linkerd, we'll use a simpler approach to verify security
# Create a basic route rule that allows all traffic to backend but captures metrics
cat << EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1beta1
kind: HTTPRoute
metadata:
  name: backend-route
  namespace: secure-apps
spec:
  parentRefs:
  - name: backend-server
    kind: Server
    group: policy.linkerd.io
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
EOF

# Test the route policy with GET
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s http://backend.secure-apps.svc.cluster.local

# Send a POST request (this should still work with our basic route)
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s -X POST http://backend.secure-apps.svc.cluster.local || echo "POST request failed"
```{{exec}}

## FedRAMP Compliance Check

Let's review how our Linkerd implementation addresses key FedRAMP requirements from NIST SP 800-53 Rev 5:

### System and Communications Protection (SC)

1. **SC-8 (Transmission Confidentiality and Integrity)**:
   - Verified mTLS encryption between all services
   - All inter-service traffic is automatically encrypted

2. **SC-13 (Cryptographic Protection)**:
   - Linkerd uses validated cryptography with TLS 1.3
   - Strong cryptographic algorithms (ECDSA P-256) for service certificates

3. **SC-17 (Public Key Infrastructure Certificates)**:
   - Linkerd operates a PKI for issuing service identity certificates
   - Certificates are automatically issued to services

4. **SC-23 (Session Authenticity)**:
   - mTLS provides mutual authentication between services
   - Session integrity is protected via TLS

### Access Control (AC)

1. **AC-3 (Access Enforcement)**:
   - Server authorization policies restrict service access based on identity
   - Verified that unauthorized services are denied access

2. **AC-4 (Information Flow Control)**:
   - HTTP route policies control information flow between services
   - Traffic can be controlled based on paths, methods, and more

3. **AC-6 (Least Privilege)**:
   - Granular access controls limit communications to only what is necessary
   - Each service only has access to authorized services

### Identification and Authentication (IA)

1. **IA-2 (Identification and Authentication - Organizational Users)**:
   - Each service has a unique SPIFFE identity tied to its service account
   - Services are uniquely identified via cryptographic verification
   - Identity is verified before any communication is permitted

2. **IA-5 (Authenticator Management)**:
   - Service certificates are automatically rotated with short lifetimes
   - Trust chain is cryptographically verified during communication
   - Certificates handle authentication between services

### Audit and Accountability (AU)

1. **AU-2 (Audit Events)**:
   - Linkerd proxies generate detailed logs for all inter-service communication
   - Both allowed and denied access attempts are recorded

2. **AU-3 (Content of Audit Records)**:
   - Logs contain detailed information including source/destination service identity
   - Timestamps and access decisions are included in records

3. **AU-12 (Audit Generation)**:
   - Automatic collection of service-to-service communication data
   - Metrics provide visibility into access patterns

### System and Information Integrity (SI)

1. **SI-4 (Information System Monitoring)**:
   - Provides golden metrics for inter-service communication health and security
   - Real-time monitoring of service mesh traffic

2. **SI-7 (Software, Firmware, and Information Integrity)**:
   - Ensures integrity of data in transit via mTLS
   - Validates service identity before communication is permitted

In the next step, we'll focus on auditing our service mesh and generating compliance evidence.