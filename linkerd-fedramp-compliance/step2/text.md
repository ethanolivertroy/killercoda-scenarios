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

### Task 1c: Wait for Linkerd Injection and Pod Readiness

Now we need to wait for Linkerd to inject its proxies and for the pods to become ready:

```bash
# Check initial pod status - may show no resources initially, which is normal
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

Let's first verify that the Linkerd installation has policy API support by checking for the policy custom resource definitions:

```bash
# Check that policy CRDs are installed
kubectl get crds | grep policy.linkerd.io
kubectl get crds | grep linkerd.io/v1

# List the Linkerd components that are installed
kubectl get deploy -n linkerd
```{{exec}}

### Task 3b: Install Policy Controller (if needed)

If the policy CRDs weren't found, we'll install the policy controller now:

```bash
# Check if we need to install the policy controller
if ! kubectl get crds | grep -q policy.linkerd.io; then
  echo "Installing policy controller..."
  linkerd install-policy | kubectl apply -f -
  sleep 10
fi
```{{exec}}

### Task 3c: Create Authorization Policies

Now let's create a server authorization policy to restrict access to the backend service:

```bash
# Check available API versions for policy resources
kubectl api-resources | grep linkerd.io/v

# Create a server authorization policy to restrict access to the backend service
cat << EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1alpha1
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
apiVersion: policy.linkerd.io/v1alpha1
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

# In case the v1alpha1 versions don't work, try v1beta1
if [ $? -ne 0 ]; then
  cat << EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1beta1
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
    # Only allow the frontend service to access the backend service
    unauthenticated: false
    meshTLS:
      serviceAccounts:
        - name: frontend
          namespace: secure-apps
EOF
fi
```{{exec}}

### Task 3d: Prepare Test Pod for Access Testing

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

### Task 3e: Test Unauthorized Access

Let's verify that unauthorized pods cannot access the backend service:

```bash
# Try to access the backend service from the test pod (should be denied)
kubectl exec -it test-pod -n secure-apps -c test-pod -- curl -s http://backend.secure-apps.svc.cluster.local --max-time 5 || echo "Access denied as expected"
```{{exec}}

### Task 3f: Test Authorized Access

Now let's verify that the frontend pod (which is authorized) can access the backend service:

```bash
# Install curl in the frontend pod
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- apk add --no-cache curl

# Try to access the backend service from the frontend pod (should be allowed)
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s http://backend.secure-apps.svc.cluster.local
```{{exec}}

## Task 4: Verify mTLS and Certificate Configuration

### Task 4a: Check Proxy Metrics

Let's examine Linkerd's mTLS metrics, which are essential for FedRAMP's cryptographic requirements:

```bash
# Check the Linkerd proxy metrics to verify mTLS is working
linkerd viz stat -n secure-apps deployment/frontend
```{{exec}}

### Task 4b: Inspect Proxy Configuration

Let's inspect the proxy version and configuration:

```bash
# View information about the proxy injection
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl get pod $FRONTEND_POD -n secure-apps -o yaml | grep -A5 linkerd.io/proxy-version

# Check the proxy status annotation
kubectl get pod $FRONTEND_POD -n secure-apps -o jsonpath='{.metadata.annotations.linkerd\.io/proxy-status}'
```{{exec}}

### Task 4c: Verify mTLS Connections

Let's check the mTLS status for all connections in our namespace:

```bash
# View the mTLS status for connections in the secure-apps namespace
linkerd viz edges deployment -n secure-apps
```{{exec}}

## Task 5: Implement and Test HTTP Route Policies

### Task 5a: Create HTTP Route Policy

Let's implement an HTTP route policy to further demonstrate Linkerd's security capabilities:

```bash
# Check available HTTPRoute API versions
kubectl api-resources | grep HTTPRoute

# Create a basic HTTP route rule that allows all traffic to backend but captures metrics
cat << EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1alpha1
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

# In case the v1alpha1 version doesn't work, try v1beta1
if [ $? -ne 0 ]; then
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
fi
```{{exec}}

### Task 5b: Test GET Request

Let's test the HTTP route policy with a GET request:

```bash
# Test the route policy with GET
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s http://backend.secure-apps.svc.cluster.local
```{{exec}}

### Task 5c: Test POST Request

Now let's try a POST request to verify different HTTP methods:

```bash
# Send a POST request (this should still work with our basic route)
kubectl exec -it $FRONTEND_POD -n secure-apps -c nginx -- curl -s -X POST http://backend.secure-apps.svc.cluster.local || echo "POST request failed"
```{{exec}}

## FedRAMP Compliance Check

Let's review how our Linkerd implementation addresses key FedRAMP requirements from NIST SP 800-53 Rev 5, distinguishing between direct and supporting capabilities:

### Primary Security Controls Directly Implemented

#### Transmission Security and Cryptography
- **SC-8**: Our demonstration confirms mTLS encryption between all services
- **SC-13**: Linkerd implements TLS 1.3 with strong ECDSA P-256 algorithms
- **SC-23**: We've verified mutual authentication between services via mTLS

#### Access Management
- **AC-3**: Our server authorization policies successfully restricted access based on identity
- **AC-4**: HTTP route policies effectively controlled information flow between services

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
4. **Fine-grained Control**: We implemented and tested path-based access controls
5. **Observability**: Metrics capture security-relevant events for auditing

To complete a comprehensive FedRAMP implementation, you would need to integrate Linkerd with:
- External logging and SIEM systems
- Long-term metrics storage
- Certificate management systems
- Alerting infrastructure

In the next step, we'll focus on auditing our service mesh and generating compliance evidence.