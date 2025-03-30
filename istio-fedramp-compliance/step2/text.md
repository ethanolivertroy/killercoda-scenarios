# Implementing mTLS and Authentication Controls

In this step, we'll deploy microservices and implement authentication controls aligned with FedRAMP requirements. NIST SP 800-204A emphasizes that authentication in microservices should use network-level security (mTLS) complemented by application-level authentication.

## Background: Authentication in Service Meshes

FedRAMP requires strong authentication controls (IA-2, IA-3, IA-5):

- **Service Identity** (IA-3): Each service must have a cryptographically verifiable identity
- **Mutual Authentication** (IA-2): Services must authenticate to each other
- **Transport Encryption** (SC-8): All communications must be encrypted
- **Authentication Policies** (AC-3): Policies should dictate which services can communicate

## Task 1: Deploy Sample Microservices

Let's deploy a set of sample microservices to demonstrate authentication controls:

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

Make sure the pods are running:

```bash
kubectl get pods -n secure-apps
```{{exec}}

## Task 2: Verify mTLS Configuration

Let's confirm that our microservices are using mTLS as required by FedRAMP (SC-8, SC-13):

```bash
# Check the mTLS status
istioctl x describe pod -n secure-apps $(kubectl get pod -n secure-apps -l app=frontend -o jsonpath={.items..metadata.name})
```{{exec}}

You should see that mTLS is enabled between services.

Let's also verify that we can't connect without proper mTLS certificates:

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

## Task 4: Verify JWT Authentication for API Access

FedRAMP requires multi-factor authentication for privileged access (IA-2). We've already implemented JWT authentication for API access with the RequestAuthentication resource we created earlier.

Let's verify that our JWT authentication is properly configured:

```bash
kubectl get requestauthentication -n secure-apps
```{{exec}}

This confirms that the backend service is configured to validate JWTs issued by "testing@secure.istio.io".

## Task 5: Test Authentication Controls

Let's test our JWT authentication policy:

```bash
# Get the frontend pod name
FRONTEND_POD=$(kubectl get pod -n secure-apps -l app=frontend -o jsonpath={.items..metadata.name})

# Access backend without JWT (should still work within the mesh due to mTLS)
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/headers
```{{exec}}

The request should succeed since it's coming from within the mesh with valid mTLS.

Now, let's first create a RequestAuthentication resource to define how JWTs should be validated:

```bash
cat << EOF | kubectl apply -f -
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
```{{exec}}

Next, we'll add an AuthorizationPolicy to enforce the JWT validation:

```bash
cat << EOF | kubectl apply -f -
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
```{{exec}}

Now try to access the backend without a JWT:

```bash
kubectl exec -n secure-apps $FRONTEND_POD -- curl -s http://backend:80/headers
```{{exec}}

The request should now be denied, as we're now enforcing JWT validation.

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