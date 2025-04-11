# Implementing OPA Gatekeeper Policies for FedRAMP Controls

In this step, we will:
1. Install OPA Gatekeeper in our Kubernetes cluster
2. Understand Gatekeeper's architecture and how it implements policy enforcement
3. Create constraint templates for key FedRAMP controls
4. Apply constraints based on these templates

> **Note:** We'll use a lightweight installation of OPA Gatekeeper that's optimized for learning environments.

## Installing OPA Gatekeeper

First, let's install OPA Gatekeeper using a pre-configured YAML file with resource optimizations:

```
# Apply the Gatekeeper installation
kubectl apply -f /root/gatekeeper.yaml
```{{exec}}

Let's check on the Gatekeeper installation progress:

```
kubectl -n gatekeeper-system get pods
```{{exec}}

## Understanding Gatekeeper Architecture

While Gatekeeper is installing, let's understand its architecture:

OPA Gatekeeper works as a validating webhook in Kubernetes that intercepts API requests and checks them against defined policies. The key components are:

1. **Constraint Templates**: Define the schema and Rego code for a type of policy
2. **Constraints**: Actual policy instances based on templates, applied to specific resources

Let's check the status of Gatekeeper:

```
kubectl -n gatekeeper-system get pods
```{{exec}}

## Creating Constraint Templates for FedRAMP Controls

Let's create a constraint template for required security labels that maps to FedRAMP CM-8 (Information System Component Inventory):

```
cat <<EOF | kubectl apply -f -
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
  annotations:
    description: Requires all resources to have a specific set of labels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          properties:
            labels:
              type: array
              items:
                type: object
                properties:
                  key:
                    type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_].key}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Missing required labels: %v", [missing])
        }
EOF
```{{exec}}

Now let's create a constraint template to block privileged containers (maps to FedRAMP AC-6: Least Privilege):

```
cat <<EOF | kubectl apply -f -
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8sprivilegedcontainer
  annotations:
    description: Blocks privileged containers
spec:
  crd:
    spec:
      names:
        kind: K8sPrivilegedContainer
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sprivilegedcontainer

        violation[{"msg": msg}] {
          c := input.review.object.spec.containers[_]
          c.securityContext.privileged
          msg := sprintf("Privileged container is not allowed: %v", [c.name])
        }
EOF
```{{exec}}

Let's verify the templates were created:

```
kubectl get constrainttemplates
```{{exec}}

## Creating FedRAMP-Compliant Constraints

Now let's create constraints that implement our FedRAMP controls. First, a constraint for required security labels:

```
cat <<EOF | kubectl apply -f -
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-security-labels
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet", "DaemonSet"]
  parameters:
    labels:
      - key: "app.kubernetes.io/name"
      - key: "security-classification" 
      - key: "owner"
EOF
```{{exec}}

Next, a constraint to block privileged containers:

```
cat <<EOF | kubectl apply -f -
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sPrivilegedContainer
metadata:
  name: no-privileged-containers
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
EOF
```{{exec}}

Let's check our constraints:

```
kubectl get constraints
```{{exec}}

## Testing Policy Enforcement

Let's test our policies by attempting to deploy a non-compliant pod:

```
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
```{{exec}}

This should be blocked by our constraints. Now let's create a compliant pod:

```
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
```{{exec}}

## Monitoring and Auditing

We can examine our policy enforcement by checking the constraints and any violations:

```
kubectl get constraints
```{{exec}}

For more detailed information on a specific constraint:

```
kubectl get constraint require-security-labels -o yaml
```{{exec}}

## Advantages of OPA Gatekeeper for FedRAMP

OPA Gatekeeper provides several advantages for FedRAMP compliance:

1. **Declarative Policy**: Policies defined as Kubernetes resources
2. **Audit Capability**: Provides audit information about violations
3. **Custom Enforcement**: Flexible policy language using Rego
4. **Resource Optimization**: Our lightweight installation is suitable for resource-constrained environments

This completes our implementation of OPA Gatekeeper policies for key FedRAMP controls. In the next step, we'll implement equivalent policies using Kyverno for comparison.