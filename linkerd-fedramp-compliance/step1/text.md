# Installing and Configuring a Secure Linkerd Mesh

In this step, we'll install Linkerd with security-focused configurations that align with FedRAMP requirements. Linkerd's security architecture is designed with a zero-trust approach, providing strong defaults that map to several NIST 800-53 controls.

## Background: Linkerd Security Architecture

Linkerd's security model centers on:

1. **Strong Service Identity**: Every service gets a cryptographic identity (SPIFFE-compatible)
2. **Automatic mTLS**: All inter-service communications are automatically encrypted
3. **Certificate Management**: Automated certificate rotation and validation
4. **Policy Enforcement**: Fine-grained access control between services

These capabilities map directly to FedRAMP requirements including:
- **SC-8/SC-13**: Transmission Confidentiality and Integrity
- **IA-2/IA-5**: Service Identification and Authenticator Management
- **AC-3/AC-4**: Access Enforcement and Information Flow Control
- **SI-4/SI-7**: System Monitoring and Information Integrity

## Task 1: Install the Linkerd CLI

### Task 1a: Download and Install CLI

First, let's download and install the Linkerd CLI which we'll use to manage our service mesh:

```bash
# Download and install the Linkerd CLI
curl -sL https://run.linkerd.io/install | sh
```{{exec}}

### Task 1b: Configure Path and Verify Installation

Now let's add Linkerd to your path and verify it's installed correctly:

```bash
# Add linkerd to your path
export PATH=$PATH:$HOME/.linkerd2/bin

# Verify the CLI is installed correctly
linkerd version
```{{exec}}

## Task 2: Verify Kubernetes Cluster Readiness

Let's check if our Kubernetes cluster is properly configured for Linkerd:

```bash
# Run pre-checks to verify cluster configuration
linkerd check --pre
```{{exec}}

This command ensures your Kubernetes cluster meets all the requirements for a Linkerd installation.

## Task 3: Install Linkerd with FedRAMP-Compliant Configuration

### Task 3a: Install Required CRDs

First, let's install the necessary Custom Resource Definitions (CRDs):

```bash
# Install Gateway API CRDs first
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Now install the Linkerd CRDs
linkerd install --crds | kubectl apply -f -
```{{exec}}

### Task 3b: Install Linkerd Control Plane

Now let's install the Linkerd control plane with security-focused settings:

```bash
# Install the Linkerd control plane with basic settings
linkerd install | kubectl apply -f -

# Wait for Linkerd to be ready
kubectl wait --for=condition=ready pod --all -n linkerd --timeout=300s
```{{exec}}

### Task 3c: Install Policy Controller

Let's install the Linkerd policy controller which is needed for authorization policies:

```bash
# Install the Linkerd Policy controller
linkerd install-policy | kubectl apply -f -

# Wait for the policy controller to be ready
kubectl wait --for=condition=ready pod -l "component=policy" -n linkerd --timeout=300s || echo "Policy controller pods not found - policy capabilities may be integrated into other components"
```{{exec}}

### Task 3d: Install Visualization Components

Let's add the Linkerd Viz extension for observability and monitoring:

```bash
# Install the Linkerd Viz extension for observability
linkerd viz install | kubectl apply -f -

# Wait for the Viz components to be ready
kubectl wait --for=condition=ready pod --all -n linkerd-viz --timeout=300s
```{{exec}}

## Task 4: Verify Installation Security

### Task 4a: Run Basic Checks

Let's verify that Linkerd has been installed securely:

```bash
# Run linkerd check to ensure everything is working correctly
linkerd check
```{{exec}}

### Task 4b: Verify Proxy and mTLS Configuration

Now let's check the proxy configuration and mTLS settings:

```bash
# Verify that mTLS is configured correctly
linkerd check --proxy

# Ensure all Linkerd components are running
kubectl get pods -n linkerd
```{{exec}}

## Task 5: Understand Linkerd's Security Components

### Task 5a: Examine Identity Components

Let's explore Linkerd's security architecture components:

```bash
# View the Linkerd identity components
kubectl get deployments -n linkerd | grep identity
```{{exec}}

### Task 5b: Inspect Certificate Authority Setup

Now let's look at how certificates are managed:

```bash
# Check the certificate authority setup
kubectl get secret linkerd-identity-issuer -n linkerd -o yaml
```{{exec}}

### Task 5c: Examine Proxy Injection Configuration

Finally, let's examine how Linkerd injects proxies into your workloads:

```bash
# Examine the Linkerd proxy injector
kubectl get deployment linkerd-proxy-injector -n linkerd -o yaml | grep -A20 containers:
```{{exec}}

## FedRAMP Compliance Check

Let's evaluate how our Linkerd installation addresses key FedRAMP requirements:

### Primary Security Controls

1. **SC-8/SC-13 (Transmission Confidentiality and Protection)**:
   - Linkerd automatically enables mTLS between all meshed services
   - Uses strong cryptographic algorithms for protection
   - TLS certificates are short-lived and automatically rotated

2. **IA-2 (Service Identification and Authentication)**:
   - Each service receives a unique SPIFFE-compatible identity
   - Identity is cryptographically verifiable
   - All communications use these identities for verification

### Supporting Capabilities  

1. **AC-3/AC-4 (Access Enforcement and Information Flow)**:
   - Policy controller enables granular service-to-service control
   - Policies can be defined based on service identity

2. **AU-2/AU-3 (Audit Events/Content)**:
   - Proxy generates logs of service-to-service communication
   - Metrics provide visibility into access patterns
   - Note: External collection systems required for complete audit trail

### Implementation Note
Our Linkerd installation provides the foundation for these security controls, but actual enforcement requires:
1. Deploying applications into the mesh
2. Defining appropriate authorization policies
3. Setting up observability and logging infrastructure

In the next step, we'll deploy applications to the mesh and implement security policies to demonstrate these capabilities.