# Understanding mTLS and Authentication Controls

In this step, we'll examine how Linkerd implements authentication controls aligned with FedRAMP requirements. Instead of deploying resource-intensive microservices, we'll focus on understanding and applying the configurations.

## Background: Authentication in Service Meshes

FedRAMP requires strong authentication controls (IA-2, IA-3, IA-5, IA-8):

- **Service Identity** (IA-3): Each service must have a cryptographically verifiable identity
- **Mutual Authentication** (IA-2): Services must authenticate to each other
- **External User Authentication** (IA-8): Non-organizational users must be authenticated
- **Certificate Management** (IA-5, SC-12, SC-17): Credentials must be properly managed and rotated
- **Transport Encryption** (SC-8): All communications must be encrypted
- **Authentication Policies** (AC-3): Policies should dictate which services can communicate

## Task 1: Examine Service Mesh Authentication

### 1.1 Understanding Linkerd's mTLS Implementation

Let's first examine how Linkerd implements mTLS by checking the control plane:

```bash
# View the Linkerd identity service configuration
kubectl get deploy -n linkerd linkerd-identity -o yaml | grep -A 10 "args:"

# Check Linkerd proxy injection configuration
kubectl get mutatingwebhookconfigurations linkerd-proxy-injector -o yaml | grep -A 10 "rules:"
```{{exec}}

Linkerd automatically provisions mTLS certificates for each workload and renews them through the identity service.

### 1.2 Check Existing Linkerd Security

Let's check the security of the Linkerd control plane components themselves:

```bash
# Examine Linkerd's own mTLS
linkerd viz edges deployment -n linkerd
```{{exec}}

You should see that traffic between Linkerd components is secured with mTLS, indicated by the padlock 🔒 icon.

## Task 2: Install the Linkerd Policy Controller

Linkerd's authorization features are provided through the policy controller. Let's install it:

```bash
linkerd install-policy-controller | kubectl apply -f -

# Wait for the policy controller to be ready
kubectl wait --for=condition=ready pod -l linkerd.io/control-plane-component=policy -n linkerd --timeout=60s
```{{exec}}

## Task 3: Understanding Authorization Policies

### 3.1 Examining Security Policy Structure

Let's examine the structure of authorization policies without deploying actual applications:

```bash
# View available policy types
kubectl api-resources | grep linkerd.io
```{{exec}}

### 3.2 Create Sample Authorization Policies

Let's create server authorization policies that would enforce authentication requirements:

```bash
cat << EOF | kubectl apply -f -
# Create the namespace if it doesn't exist
apiVersion: v1
kind: Namespace
metadata:
  name: secure-apps
  annotations:
    linkerd.io/inject: enabled
---
# Sample service accounts (just the definitions)
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
apiVersion: v1
kind: ServiceAccount
metadata:
  name: database
  namespace: secure-apps
---
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
---
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

### 3.3 Verify the Policies

Let's check that our policies have been created:

```bash
kubectl get server,serverauthorization -n secure-apps
```{{exec}}

## Task 4: Analyze Authentication and Authorization Policies

### 4.1 Understanding Authorized Service Access

Let's examine how the frontend is authorized to access the backend:

```bash
# Examine the backend service authorization policy
kubectl get serverauthorization backend-server-auth -n secure-apps -o yaml
```{{exec}}

This policy allows only the frontend service identity to access the backend service.

### 4.2 Understanding Denied Access Patterns

Now let's examine why direct access from frontend to database is denied:

```bash
# Examine the database service authorization policy
kubectl get serverauthorization database-server-auth -n secure-apps -o yaml
```{{exec}}

This policy only allows the backend service identity to access the database, not the frontend.

### 4.3 Understanding Service Identity

Let's examine how Linkerd uses service accounts for identity:

```bash
# Look at our service accounts
kubectl get serviceaccounts -n secure-apps
```{{exec}}

Linkerd uses the Kubernetes service account as the foundation for service identity in the mesh.

## Task 5: Adding Network Policies for Defense-in-Depth

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

## FedRAMP and NIST Compliance Analysis

Let's analyze how these configurations satisfy FedRAMP requirements:

```bash
# Examine the combined security model
cat << EOF > /tmp/security-analysis.txt
# FedRAMP Compliance Analysis for Linkerd Authentication Controls

## Authentication Requirements (IA-2, IA-3, IA-5)
- ✅ Service Identity: Provided by Linkerd's identity service using service accounts
- ✅ Mutual Authentication: Enforced by ServerAuthorization policies requiring mTLS
- ✅ Certificate Management: Handled automatically by Linkerd identity service

## Access Control Requirements (AC-3, AC-6)
- ✅ Least Privilege: Fine-grained control through service identity-based policies
- ✅ AuthZ: Server/ServerAuthorization resources define precise access rules
- ✅ Defense-in-Depth: Kubernetes NetworkPolicies provide additional layer

## Encryption Requirements (SC-8, SC-13)
- ✅ Transport Encryption: Automatic mTLS between all meshed services
- ✅ Cryptographic Protocols: Modern TLS implementations with secure algorithms

## Audit Requirements (AU-2)
- ✅ Access Enforcement Logging: Policy violations logged by Linkerd proxies
- ✅ Centralized Visibility: Linkerd dashboard shows mesh-wide security status
EOF

cat /tmp/security-analysis.txt
```{{exec}}

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