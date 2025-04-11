# Implementing Kyverno Policies for FedRAMP Controls

In this step, we will:
1. Install Kyverno in our Kubernetes cluster
2. Understand Kyverno's architecture and how it differs from OPA Gatekeeper
3. Create policies that implement key FedRAMP controls
4. Test our policies with compliant and non-compliant resources

> **Note:** Like Gatekeeper, Kyverno also requires resources. We've selected a stable version and modified the verification steps to allow you to proceed as long as the key components are installed, even if some pods are not fully ready.

## Installing Kyverno

Let's install Kyverno directly with YAML manifests:

```
# Create namespace
kubectl create namespace kyverno

# Install Kyverno v1.10.0 (a stable version)
kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/v1.10.0/config/release/install.yaml
```{{exec}}

Wait for Kyverno to be fully deployed (this may take a few minutes):

```
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=300s
```{{exec}}

> **Note:** If the above command times out, you can check the pod status manually with `kubectl get pods -n kyverno` and proceed once the pods are in the Running state.

## Understanding Kyverno Architecture

Kyverno works as an admission controller that intercepts Kubernetes API requests and validates them against policies. Key differences from Gatekeeper include:

1. **Native YAML**: Kyverno uses Kubernetes-native YAML instead of Rego for policy definition
2. **All-in-One**: Policies contain both the schema and the rules (no separate templates)
3. **Mutation Support**: Kyverno can mutate resources, not just validate them
4. **Pattern Matching**: Policies use pattern matching instead of custom language logic

Let's check that Kyverno is properly installed:

```
kubectl get pods -n kyverno
```{{exec}}

## Creating Kyverno Policies for FedRAMP Controls

We'll create policies that implement the same controls we did with OPA Gatekeeper. Let's examine our Kyverno policies file:

```
cat /root/kyverno-policies.yaml
```{{exec}}

Now, let's apply these policies:

```
kubectl apply -f /root/kyverno-policies.yaml
```{{exec}}

Verify that the policies were created:

```
kubectl get cpol
```{{exec}}

## Examining Key FedRAMP Policies

Let's look at each policy we've implemented and understand how it maps to FedRAMP controls:

1. **Required Labels Policy** (CM-8: Information System Component Inventory)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-security-labels
  annotations:
    policies.kyverno.io/title: Required Security Labels
    policies.kyverno.io/category: FedRAMP Component Inventory
    policies.kyverno.io/severity: medium
    policies.kyverno.io/subject: Pod, Deployment, StatefulSet, DaemonSet
    policies.kyverno.io/description: >-
      This policy requires that specific security labels are defined in the metadata
      to ensure proper inventory management for FedRAMP CM-8 compliance.
spec:
  validationFailureAction: enforce
  background: true
  rules:
  - name: require-labels
    match:
      resources:
        kinds:
        - Pod
        - Deployment
        - StatefulSet
        - DaemonSet
    validate:
      message: "The following labels are required: app.kubernetes.io/name, security-classification, owner"
      pattern:
        metadata:
          labels:
            app.kubernetes.io/name: "?*"
            security-classification: "?*"
            owner: "?*"
```

2. **Block Privileged Containers** (AC-6: Least Privilege)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-privileged-containers
  annotations:
    policies.kyverno.io/title: Restrict Privileged Containers
    policies.kyverno.io/category: FedRAMP Least Privilege
    policies.kyverno.io/severity: high
    policies.kyverno.io/subject: Pod
    policies.kyverno.io/description: >-
      Restricts privileged containers to enforce least privilege principle 
      required by FedRAMP AC-6.
spec:
  validationFailureAction: enforce
  background: true
  rules:
  - name: privileged-containers
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Privileged containers are not allowed"
      pattern:
        spec:
          containers:
          - name: "*"
            securityContext:
              privileged: "false" # Use string boolean for pattern matching
```

3. **Allowed Repositories** (CM-7: Least Functionality)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: allowed-image-registries
  annotations:
    policies.kyverno.io/title: Allowed Image Registries
    policies.kyverno.io/category: FedRAMP Least Functionality
    policies.kyverno.io/severity: high
    policies.kyverno.io/subject: Pod
    policies.kyverno.io/description: >-
      Restricts container images to trusted registries for FedRAMP CM-7 compliance.
spec:
  validationFailureAction: enforce
  background: true
  rules:
  - name: validate-registries
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Images must come from trusted registries"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "{{regex_match('(gcr.io/my-fedramp-project/|registry.internal.fedramp.gov/|k8s.gcr.io/|docker.io/bitnami/).*', images.containers.*.image)}}"
```

4. **Resource Limits** (SC-6: Resource Availability)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
  annotations:
    policies.kyverno.io/title: Resource Limits Required
    policies.kyverno.io/category: FedRAMP Resource Availability
    policies.kyverno.io/severity: medium
    policies.kyverno.io/subject: Pod
    policies.kyverno.io/description: >-
      Requires CPU and memory limits for all containers to protect against resource
      exhaustion attacks, supporting FedRAMP SC-6 compliance.
spec:
  validationFailureAction: enforce
  background: true
  rules:
  - name: validate-resources
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "CPU and memory limits are required for all containers"
      pattern:
        spec:
          containers:
          - name: "*"
            resources:
              limits:
                memory: "?*"
                cpu: "?*"
```

## Testing Policy Enforcement

Let's test our policies by attempting to deploy a non-compliant pod:

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: kyverno-non-compliant-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:latest
EOF
```{{exec}}

This should be blocked by our policies. Now let's create a compliant pod:

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: kyverno-compliant-pod
  namespace: default
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
```{{exec}}

## Monitoring and Reporting

Kyverno provides several ways to monitor policy enforcement:

```
# Check policy reports
kubectl get policyreport -A
```{{exec}}

```
# Get detailed information about a specific policy
kubectl get cpol require-security-labels -o yaml
```{{exec}}

## Comparing Kyverno to Gatekeeper

Let's compare the two approaches:

| Feature | OPA Gatekeeper | Kyverno |
|---------|----------------|---------|
| Policy Language | Rego (custom query language) | Kubernetes-native YAML |
| Policy Structure | Separate templates and constraints | Single policy resource |
| Learning Curve | Steeper (requires learning Rego) | Lower (similar to Kubernetes resources) |
| Flexibility | More powerful for complex logic | Simpler for common patterns |
| Mutation Support | Limited | Extensive |
| Resource Usage | Higher | Lower |

This completes our implementation of Kyverno policies for key FedRAMP controls. In the next step, we'll focus on auditing and documenting policy compliance for FedRAMP authorization evidence.