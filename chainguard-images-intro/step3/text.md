# Building with Chainguard Images

In this final step, we'll create a custom application using a Chainguard Image as a base. We'll also explore how to verify and trust Chainguard Images in a production environment.

## Building a Custom Application

Let's create a simple Go application and package it using a Chainguard Image:

```bash
# Set up a Go application
mkdir -p ~/go-app
cat << EOF > ~/go-app/main.go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        hostname, _ := os.Hostname()
        fmt.Fprintf(w, "Hello, World from %s!\n", hostname)
        fmt.Fprintf(w, "Running on Chainguard Images\n")
    })

    fmt.Println("Server starting on port 8080...")
    http.ListenAndServe(":8080", nil)
}
EOF

# Write a Dockerfile using Chainguard's Go image for building
# and static image for running
cat << EOF > ~/go-app/Dockerfile
# Build stage
FROM cgr.dev/chainguard/go:latest as builder
WORKDIR /app
COPY main.go .
RUN CGO_ENABLED=0 go build -o server main.go

# Run stage
FROM cgr.dev/chainguard/static:latest
WORKDIR /app
COPY --from=builder /app/server .
EXPOSE 8080
USER nonroot
CMD ["/app/server"]
EOF

# Build the application
cd ~/go-app
docker build -t secure-app:latest .

# Run the application
docker run -d -p 8080:8080 --name secure-app secure-app:latest

# Test the application
curl http://localhost:8080
```{{exec}}

## Image Analysis

Let's analyze our newly built secure application:

```bash
# Check the size of our image
docker images secure-app:latest

# Scan for vulnerabilities
trivy image secure-app:latest

# Look at the layers to understand the build
docker inspect secure-app:latest | jq '.[0].RootFS.Layers | length'
docker history secure-app:latest
```{{exec}}

You'll notice that our final image is very small and has few if any vulnerabilities. This is because:
1. We built our Go app with CGO_ENABLED=0 for a static binary
2. We used the minimalist cgr.dev/chainguard/static base image
3. We're running as a non-root user

## Verifying Chainguard Images in Production

In a production environment, you'll want to verify the authenticity and integrity of Chainguard Images. Let's see how to do that:

```bash
# Verify Chainguard image using cosign
cosign verify cgr.dev/chainguard/go:latest

# View attestations (metadata about the image)
cosign verify-attestation --type spdx cgr.dev/chainguard/go:latest

# View vulnerability scan results
cosign verify-attestation --type vuln cgr.dev/chainguard/go:latest | jq -r '.payload' | base64 -d | jq '.predicate.scanner.result.passes'
```{{exec}}

## Integrating with CI/CD

In a CI/CD pipeline, you can enforce policies to only allow verified Chainguard Images. Here's a sample script that could be used in CI:

```bash
# Write a sample CI validation script
cat << EOF > ~/validate-image.sh
#!/bin/bash
set -e

IMAGE="\$1"

echo "Validating image: \$IMAGE"

# 1. Verify signature
if cosign verify "\$IMAGE"; then
  echo " Signature verification passed"
else
  echo "L Signature verification failed"
  exit 1
fi

# 2. Check for vulnerabilities
if trivy image "\$IMAGE" --severity HIGH,CRITICAL --exit-code 1; then
  echo " No HIGH or CRITICAL vulnerabilities found"
else
  echo "L HIGH or CRITICAL vulnerabilities found"
  exit 1
fi

echo "Image validation complete: \$IMAGE is secure"
EOF

chmod +x ~/validate-image.sh

# Test our script on a Chainguard image (should pass)
~/validate-image.sh cgr.dev/chainguard/static:latest || echo "Validation failed"
```{{exec}}

## Bonus: DevOps Integration Tips

### Kubernetes Integration

In Kubernetes, you can use admission controllers like Kyverno or OPA Gatekeeper to enforce the use of Chainguard Images:

```bash
# Example Kyverno policy to require Chainguard images
cat << EOF > ~/require-chainguard.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-chainguard-images
spec:
  validationFailureAction: Enforce
  rules:
  - name: verify-chainguard
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Only Chainguard images are allowed"
      pattern:
        spec:
          containers:
          - image: "cgr.dev/chainguard/*"
EOF

echo "This policy could be applied to a Kubernetes cluster to enforce Chainguard Images usage"
```{{exec}}

## Cleanup

Let's clean up our environment:

```bash
# Stop the running container
docker stop secure-app
docker rm secure-app

# Clean up files (optional)
echo "All tasks completed!"
```{{exec}}

Congratulations on completing the Chainguard Images tutorial! You've learned about the security benefits of minimal, distroless images, how to use them, and how to integrate them into your workflow.