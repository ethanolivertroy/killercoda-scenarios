# Setting Up a Compliant Linkerd Service Mesh

The foundation of FedRAMP compliance in a service mesh environment starts with a properly configured Linkerd installation. NIST SP 800-204B specifically recommends service meshes for implementing security controls in microservice environments.

## Background: Service Mesh Security and FedRAMP

Linkerd provides critical security capabilities that align with FedRAMP requirements:

- **Zero Trust Architecture** (AC-3, AC-6, SC-7): Linkerd enables a zero trust model by enforcing authentication and authorization for all service-to-service communication
- **Transport Layer Security** (SC-8, SC-12, SC-13, SC-17): Linkerd provides automatic mTLS for encrypted communications with automated certificate management
- **Centralized Policy Management** (CM-6, CM-7): Consistent enforcement of security policies across services
- **Strong Identity** (IA-2, IA-3, IA-5): Service identity based on cryptographic attestation
- **Comprehensive Monitoring** (AU-2, AU-3, AU-12, SI-4): Detailed telemetry for service interactions

## Task 1: Install Linkerd with Secure Configuration

### 1.1 Download and Install Linkerd CLI

First, let's download and install the Linkerd CLI:

```bash
curl -fsL https://run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin
```{{exec}}

### 1.2 Validate Kubernetes Cluster

Let's check that our Kubernetes cluster meets the requirements for Linkerd:

```bash
linkerd check --pre
```{{exec}}

### 1.3 Install Linkerd with FedRAMP-Compliant Settings

Let's install Linkerd with security settings aligned with FedRAMP requirements:

```bash
# Install Kubernetes Gateway API CRDs first
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Install Linkerd CRDs second
linkerd install --crds | kubectl apply -f -

# Install Linkerd with FedRAMP-compliant default settings
# This avoids certificate generation issues and simplifies the installation
linkerd install \
  --set proxyInit.runAsRoot=true \
  --set proxyInit.resources.cpu.request=100m \
  --set proxyInit.resources.cpu.limit=100m \
  --set proxyInit.resources.memory.request=50Mi \
  --set proxyInit.resources.memory.limit=50Mi \
  --set proxy.resources.cpu.request=100m \
  --set proxy.resources.cpu.limit=1000m \
  --set proxy.resources.memory.request=20Mi \
  --set proxy.resources.memory.limit=250Mi \
  --set proxy.enableExternalProfiles=true \
  --set proxy.logLevel=info \
  --set proxy.logFormat=json \
  --set controllerResources.cpu.request=100m \
  --set controllerResources.cpu.limit=1000m \
  --set controllerResources.memory.request=50Mi \
  --set controllerResources.memory.limit=250Mi | kubectl apply -f -
```{{exec}}

## Task 2: Install Visualization for Monitoring

FedRAMP requires comprehensive security monitoring (AU-2, AU-12, SI-4). Let's set up the Linkerd visualization extension:

```bash
linkerd viz install | kubectl apply -f -
```{{exec}}

## Task 3: Verify Installation and Security

### 3.1 Check Linkerd Installation

Let's verify that Linkerd is properly installed with our security settings:

```bash
linkerd check
```{{exec}}

### 3.2 Check Linkerd Viz Installation

Verify the visualization components (important for monitoring requirements in FedRAMP):

```bash
linkerd viz check
```{{exec}}

### 3.3 Check mTLS Configuration

Let's verify that our automatic mTLS is properly configured:

```bash
linkerd viz edges deployment -n linkerd
```{{exec}}

This command should show that connections between Linkerd components are secured with mTLS.

## Task 4: Create a Secure Application Namespace

Now, let's create a dedicated namespace with automatic Linkerd proxy injection enabled:

```bash
# Create the namespace
kubectl create namespace secure-apps

# Enable Linkerd injection for the namespace
kubectl annotate namespace secure-apps linkerd.io/inject=enabled

# Verify the namespace annotation
kubectl get namespace secure-apps -o jsonpath='{.metadata.annotations}'
```{{exec}}

## Task 5: Deploy Network Policies for Added Security

In addition to Linkerd's built-in security, let's add Kubernetes NetworkPolicies for another layer of security:

```bash
cat <<EOF | kubectl apply -f -
# Create a default deny policy for the secure-apps namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: secure-apps
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```{{exec}}

## Task 6: Verify Security Configuration

Let's check our overall security configuration:

```bash
# Check Linkerd proxy injection status
kubectl get ns secure-apps -o json | jq '.metadata.annotations'

# View all network policies
kubectl get networkpolicy -n secure-apps

# Check Linkerd identity service status
kubectl get deploy -n linkerd linkerd-identity
```{{exec}}

## NIST Compliance Check

According to NIST SP 800-204B, a service mesh should establish a security perimeter by:
1. Enforcing mutual TLS between services
2. Implementing strong service identity
3. Providing centralized policy management

Our Linkerd configuration implements all these requirements through:
- Automatic mTLS for all communications
- Secure identity-based certificates for all services with proper crypto materials
- Centralized policy enforcement capability through the control plane
- Additional network policies for defense-in-depth

In the next step, we'll focus on authentication controls and implementing more granular authorization policies in alignment with FedRAMP requirements.