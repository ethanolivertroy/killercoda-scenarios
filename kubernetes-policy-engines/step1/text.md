# Implementing OPA Gatekeeper Policies for FedRAMP Controls

In this step, we will:
1. Install OPA Gatekeeper in our Kubernetes cluster
2. Understand Gatekeeper's architecture and how it implements policy enforcement
3. Create constraint templates for key FedRAMP controls
4. Apply constraints based on these templates

## Installing OPA Gatekeeper

First, let's install OPA Gatekeeper:

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

Wait for Gatekeeper to be fully deployed:

```bash
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=90s
```

## Understanding Gatekeeper Architecture

OPA Gatekeeper works as a validating webhook in Kubernetes that intercepts API requests and checks them against defined policies. The key components are:

1. **Constraint Templates**: Define the schema and Rego code for a type of policy
2. **Constraints**: Actual policy instances based on templates, applied to specific resources

Let's check that Gatekeeper is properly installed:

```bash
kubectl get pods -n gatekeeper-system
```

## Creating Constraint Templates for FedRAMP Controls

We'll create constraint templates that address key FedRAMP control families. Each template will include:
- Parameters for configuration
- Rego code that implements the policy logic
- Clear violation messages for audit purposes

Let's examine our first template for required security labels (maps to CM-8):

```bash
cat /root/opa-constraints.yaml
```

Now, let's apply these constraint templates:

```bash
kubectl apply -f /root/opa-constraints.yaml
```

Verify that the templates were created:

```bash
kubectl get constrainttemplates
```

## Implementing FedRAMP Controls with Constraints

Now we'll create constraints based on our templates. Each constraint will:
1. Reference a constraint template
2. Define the scope (which resources it applies to)
3. Set parameters specific to our security requirements

Let's create constraints for:

1. **Required Labels** (CM-8: Information System Component Inventory)
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-security-labels
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod", "Deployment", "StatefulSet", "DaemonSet"]
  parameters:
    labels:
      - key: "app.kubernetes.io/name"
      - key: "security-classification"
      - key: "owner"
```

2. **Privileged Container Prevention** (AC-6: Least Privilege)
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sBlockPrivilegedContainers
metadata:
  name: prevent-privileged-containers
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
```

3. **Allowed Repositories** (CM-7: Least Functionality)
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-image-repos
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    repos:
      - "gcr.io/my-fedramp-project/"
      - "registry.internal.fedramp.gov/"
      - "k8s.gcr.io/"
      - "docker.io/bitnami/"
```

4. **Resource Limits** (SC-6: Resource Availability)
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredResources
metadata:
  name: require-resource-limits
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    resources: ["limits.cpu", "limits.memory"]
```

Let's apply these constraints:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-security-labels
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod", "Deployment", "StatefulSet", "DaemonSet"]
  parameters:
    labels:
      - key: "app.kubernetes.io/name"
      - key: "security-classification"
      - key: "owner"
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sBlockPrivilegedContainers
metadata:
  name: prevent-privileged-containers
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-image-repos
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    repos:
      - "gcr.io/my-fedramp-project/"
      - "registry.internal.fedramp.gov/"
      - "k8s.gcr.io/"
      - "docker.io/bitnami/"
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredResources
metadata:
  name: require-resource-limits
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    resources: ["limits.cpu", "limits.memory"]
EOF
```

## Testing Policy Enforcement

Let's test our policies by attempting to deploy a non-compliant pod:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    securityContext:
      privileged: true
EOF
```

This should be blocked by our policies. Now let's create a compliant pod:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  labels:
    app.kubernetes.io/name: secure-app
    security-classification: internal
    owner: security-team
spec:
  containers:
  - name: nginx
    image: docker.io/bitnami/nginx:latest
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
      requests:
        cpu: "50m"
        memory: "64Mi"
EOF
```

Let's examine our constraints and any violations:

```bash
kubectl get constraints
```

## Monitoring and Auditing

We can examine audit results to see resources that were created before our policies or were exempted:

```bash
kubectl get constraint require-security-labels -o yaml
```

This completes our implementation of OPA Gatekeeper policies for key FedRAMP controls. In the next step, we'll implement equivalent policies using Kyverno.