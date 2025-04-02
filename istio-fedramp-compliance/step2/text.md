# Implementing mTLS and Authentication Controls

In this step, we'll deploy microservices and implement authentication controls aligned with FedRAMP requirements. NIST SP 800-204A emphasizes that authentication in microservices should use network-level security (mTLS) complemented by application-level authentication.

## Background: Authentication in Service Meshes

FedRAMP requires strong authentication controls (IA-2, IA-3, IA-5, IA-8):

- **Service Identity** (IA-3): Each service must have a cryptographically verifiable identity
- **Mutual Authentication** (IA-2): Services must authenticate to each other
- **External User Authentication** (IA-8): Non-organizational users must be authenticated (via JWT)
- **Certificate Management** (IA-5, SC-12, SC-17): Credentials must be properly managed and rotated
- **Transport Encryption** (SC-8): All communications must be encrypted
- **Authentication Policies** (AC-3): Policies should dictate which services can communicate

## Task 1: Deploy Sample Microservices

### 1.1 Create Service Accounts and Deployments

Let's deploy a set of sample microservices with distinct service accounts to demonstrate authentication controls:

```bash
cat << EOF | kubectl apply -f -
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
      labels:
        app: frontend
    spec:
      serviceAccountName: frontend
      containers:
      - name: httpbin
        image: curlimages/curl:7.83.1
        command: ["sleep", "infinity"]
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
      labels:
        app: backend
    spec:
      serviceAccountName: backend
      containers:
      - name: httpbin
        image: docker.io/kennethreitz/httpbin
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
```{{exec}}

### 1.2 Verify Microservices Deployment

Make sure the pods are running:

```bash
kubectl get pods -n secure-apps
```{{exec}}

## Task 2: Verify mTLS Configuration

### 2.1 Check mTLS Status for Pods

Let's confirm that our microservices are using mTLS as required by FedRAMP (SC-8, SC-13):

```bash
# Check the mTLS status
istioctl x describe pod -n secure-apps $(kubectl get pod -n secure-apps -l app=frontend -o jsonpath={.items..metadata.name})
```{{exec}}

You should see that mTLS is enabled between services.

### 2.2 Test mTLS Enforcement

Let's verify that we can't connect without proper mTLS certificates:

```bash
# Create a pod without istio-injection to test
kubectl create namespace non-secure
kubectl run test-pod --image=curlimages/curl -n non-secure -- sleep 3600
kubectl wait --for=condition=ready pod/test-pod -n non-secure --timeout=60s

# Try to access the backend service from outside the mesh (should fail)
kubectl exec -it test-pod -n non-secure -- curl -v backend.secure-apps.svc.cluster.local
```{{exec}}

This should fail since the test pod doesn't have the required mTLS certificates.

## Task 3: Configure Workload-Specific mTLS Policies

### 3.1 Define Granular mTLS Policies

While cluster-wide mTLS is good, FedRAMP's least privilege principle (AC-6) requires granular control. Let's create namespace and workload-specific PeerAuthentication policies:

```bash
cat << EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: frontend-mtls
  namespace: secure-apps
spec:
  selector:
    matchLabels:
      app: frontend
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: backend-mtls
  namespace: secure-apps
spec:
  selector:
    matchLabels:
      app: backend
  mtls:
    mode: STRICT
EOF
```{{exec}}

## Task 4: Configure and Verify JWT Authentication

### 4.1 Check Existing JWT Configuration

FedRAMP requires multi-factor authentication for privileged access (IA-2, IA-8). Let's first check if any JWT authentication is already configured:

```bash
# Check if RequestAuthentication is applied
kubectl get requestauthentication -n secure-apps
kubectl get authorizationpolicy -n secure-apps
```{{exec}}

This confirms that the backend service is configured to validate JWTs issued by "testing@secure.istio.io" and enforce JWT validation through the AuthorizationPolicy.

## Task 5: Implement and Test JWT Authentication

### 5.1 Test Initial Service Access

Let's test our initial service-to-service authentication:

```bash
# Get the frontend pod name
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath={.items..metadata.name})

# Access backend without JWT (should work with just mTLS)
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/headers
```{{exec}}

The request should succeed since it's coming from within the mesh with valid mTLS.

### 5.2 Configure JWT Authentication

Now, let's create a RequestAuthentication resource to define how JWTs should be validated:

```bash
cat << EOF > /root/request-auth.yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-authentication
  namespace: secure-apps
spec:
  selector:
    matchLabels:
      app: backend
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.17/security/tools/jwt/samples/jwks.json"
EOF

kubectl apply -f /root/request-auth.yaml
```{{exec}}

### 5.3 Define JWT Authorization Policy

Next, we'll add an AuthorizationPolicy to enforce the JWT validation:

```bash
cat << EOF > /root/auth-policy.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: secure-apps
spec:
  selector:
    matchLabels:
      app: backend
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["*"]
    when:
    - key: request.auth.claims[iss]
      values: ["testing@secure.istio.io"]
EOF

kubectl apply -f /root/auth-policy.yaml
```{{exec}}

### 5.4 Implement Default Deny Policy

Let's create a default deny policy for our secure-apps namespace:

```bash
cat << EOF > /root/default-deny.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: default-deny
  namespace: secure-apps
spec:
  {}
EOF

kubectl apply -f /root/default-deny.yaml

# Verify the resources were created
kubectl get requestauthentication,authorizationpolicy -n secure-apps
```{{exec}}

### 5.5 Test JWT Authentication Enforcement

Now try to access the backend without a JWT:

```bash
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/headers
```{{exec}}

The request should now be denied, as we're enforcing JWT validation.

Let's try with a valid JWT:

```bash
TOKEN=$(curl -s https://raw.githubusercontent.com/istio/istio/release-1.17/security/tools/jwt/samples/demo.jwt)
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/headers -H "Authorization: Bearer $TOKEN"
```{{exec}}

This should succeed since we're providing a valid JWT token.

## NIST Compliance Check

According to NIST SP 800-204B, secure service-to-service communication should implement:
1. Transport layer security (mTLS)
2. Service authentication based on identity
3. Authorization based on identity and attributes

Our configuration satisfies these requirements through:
- Strict mTLS for transport security
- Service account-based identity for service authentication
- JWT validation for API access

In the next step, we'll focus on authorization policies and network security to further enhance our FedRAMP compliance.