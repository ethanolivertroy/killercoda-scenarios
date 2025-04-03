# Implementing mTLS and Authentication Controls

In this step, we'll deploy microservices and implement authentication controls aligned with FedRAMP requirements. NIST SP 800-204A emphasizes that authentication in microservices should use network-level security (mTLS) complemented by application-level authentication.

## Background: Authentication in Service Meshes

FedRAMP requires strong authentication controls (IA-2, IA-3, IA-5, IA-8):

- **Service Identity** (IA-3): Each service must have a cryptographically verifiable identity
- **Mutual Authentication** (IA-2): Services must authenticate to each other
- **External User Authentication** (IA-8): Non-organizational users must be authenticated
- **Certificate Management** (IA-5, SC-12, SC-17): Credentials must be properly managed and rotated
- **Transport Encryption** (SC-8): All communications must be encrypted
- **Authentication Policies** (AC-3): Policies should dictate which services can communicate

## Task 1: Deploy Sample Microservices

### 1.1 Create Service Accounts and Deployments

Let's deploy a set of sample microservices with distinct service accounts to demonstrate authentication controls:

```bash
kubectl apply -f /root/sample-microservices.yaml
```{{exec}}

Wait for the pods to become ready:

```bash
# Wait with a shorter timeout for each pod
kubectl wait --for=condition=ready pod -l app=frontend -n secure-apps --timeout=60s
kubectl wait --for=condition=ready pod -l app=backend -n secure-apps --timeout=60s
kubectl wait --for=condition=ready pod -l app=database -n secure-apps --timeout=60s

# If pods aren't ready, check their status
kubectl get pods -n secure-apps

# Troubleshooting: If pods are stuck in Pending state, check node resources
kubectl describe pods -n secure-apps | grep -A 10 "Events:"
kubectl describe nodes | grep -A 5 "Allocated resources"
```{{exec}}

### 1.2 Verify Microservices Deployment

Make sure the pods are running and properly meshed with Linkerd:

```bash
kubectl get pods -n secure-apps
linkerd viz stat deploy -n secure-apps
```{{exec}}

## Task 2: Verify mTLS Configuration

### 2.1 Check mTLS Status for Pods

Let's confirm that our microservices are using mTLS as required by FedRAMP (SC-8, SC-13):

```bash
# Check the mTLS status
linkerd viz edges deployment -n secure-apps
```{{exec}}

You should see that traffic between services is secured with mTLS, indicated by the padlock 🔒 icon.

Let's also check the mesh status of individual pods:

```bash
linkerd viz stat pods -n secure-apps
```{{exec}}

### 2.2 Test mTLS Enforcement

Let's verify that we can't connect without proper mTLS certificates:

```bash
# Create a pod without linkerd-injection to test
kubectl create namespace non-secure
kubectl run test-pod --image=curlimages/curl -n non-secure -- sleep 3600
kubectl wait --for=condition=ready pod/test-pod -n non-secure --timeout=60s

# Try to access the backend service from outside the mesh
kubectl exec -it test-pod -n non-secure -- curl -v backend.secure-apps.svc.cluster.local
```{{exec}}

This request should still work because Linkerd allows communication from non-meshed workloads by default. We'll address this in the next step with proper authorization policies.

## Task 3: Implement Authorization Controls

### 3.1 Install the Linkerd Policy Controller

Linkerd's authorization features are provided through the policy controller. Let's install it:

```bash
linkerd install-policy-controller | kubectl apply -f -

# Wait for the policy controller to be ready
kubectl wait --for=condition=ready pod -l linkerd.io/control-plane-component=policy -n linkerd --timeout=60s
```{{exec}}

### 3.2 Create Server Authorization Policies

Let's create server authorization policies to enforce authentication requirements:

```bash
cat << EOF | kubectl apply -f -
# Server authorization for backend service
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  name: backend-server-auth
  namespace: secure-apps
spec:
  server:
    selector:
      matchLabels:
        app: backend
  client:
    # Only allow authenticated traffic from specific services
    meshTLS:
      unauthenticated: false
      identities:
      - "frontend.secure-apps.serviceaccount.identity.linkerd.cluster.local"
---
# Server authorization for database service
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  name: database-server-auth
  namespace: secure-apps
spec:
  server:
    selector:
      matchLabels:
        app: database
  client:
    # Only allow authenticated traffic from backend
    meshTLS:
      unauthenticated: false
      identities:
      - "backend.secure-apps.serviceaccount.identity.linkerd.cluster.local"
EOF
```{{exec}}

### 3.3 Create a Server Policy

Now let's create a server policy to enforce the authorization requirements:

```bash
cat << EOF | kubectl apply -f -
# Server policy for backend
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
# Server policy for database
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  name: database-server
  namespace: secure-apps
spec:
  podSelector:
    matchLabels:
      app: database
  port: 80
  proxyProtocol: HTTP/1
EOF
```{{exec}}

### 3.4 Verify the Policies

Let's check that our policies have been created:

```bash
kubectl get server,serverauthorization -n secure-apps
```{{exec}}

## Task 4: Test Authentication and Authorization Enforcement

### 4.1 Test with Authorized Service

Let's test that our frontend can access the backend (authorized):

```bash
# Get the frontend pod name
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath={.items..metadata.name})

# Access backend with proper mTLS (should work)
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/headers
```{{exec}}

The request should succeed since it's coming from the frontend service with proper mTLS identity.

### 4.2 Test Direct Access to Database (Should Fail)

Now let's test accessing the database directly from frontend (should be denied):

```bash
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://database:80/headers
```{{exec}}

This should fail because our policies only allow the backend to access the database.

### 4.3 Test Access from Backend to Database (Should Work)

Let's verify the backend can access the database:

```bash
# Get the backend pod name
BACKEND_POD=$(kubectl get pod -n secure-apps -l app=backend -o jsonpath={.items..metadata.name})

# Access database from backend (should work)
kubectl exec -n secure-apps $BACKEND_POD -- curl -s http://database:80/headers
```{{exec}}

This should succeed since the backend is authorized to access the database.

### 4.4 Test with Non-Meshed Pod (Should Fail)

Let's verify our policies prevent access from non-meshed workloads:

```bash
# Try to access the backend from non-meshed pod
kubectl exec -it test-pod -n non-secure -- curl -v backend.secure-apps.svc.cluster.local
```{{exec}}

This should now fail because our ServerAuthorization policy requires mTLS authentication and specific service identity.

## Task 5: Implement Network Policies for Additional Security

To provide defense-in-depth, let's add Kubernetes NetworkPolicies to complement our Linkerd policies:

```bash
cat << EOF | kubectl apply -f -
# Allow traffic only from frontend to backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: secure-apps
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
---
# Allow traffic only from backend to database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: secure-apps
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
EOF
```{{exec}}

### 5.1 Verify Network Policies

Let's check our network policies:

```bash
kubectl get networkpolicy -n secure-apps
```{{exec}}

## NIST Compliance Check

According to NIST SP 800-204B, secure service-to-service communication should implement:
1. Transport layer security (mTLS)
2. Service authentication based on identity
3. Authorization based on identity and attributes

Our configuration satisfies these requirements through:
- Automatic mTLS for transport security between all meshed services
- Service account-based identity for service authentication
- Server authorization policies based on service identity
- Network policies for additional layer of defense

In the next step, we'll focus on auditing authorization policies and network security to further enhance our FedRAMP compliance.