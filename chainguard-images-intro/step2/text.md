# Running and Inspecting Chainguard Images

In this step, we'll run applications using Chainguard Images and inspect them to understand their security properties better.

## Running a Simple Application

Let's run a simple Python application using a Chainguard Image:

```bash
# Create a simple Python script
mkdir -p ~/python-app
cat << EOF > ~/python-app/app.py
import sys
import platform

print("Hello from Chainguard Python image!")
print(f"Python version: {sys.version}")
print(f"Platform: {platform.platform()}")
EOF

# Run the script with the Chainguard Python image
docker run --rm -v ~/python-app:/app cgr.dev/chainguard/python:latest-dev python /app/app.py
```{{exec}}

## Inspecting Image Contents

Now let's inspect the contents of the Chainguard image to understand what's inside:

```bash
# Create a container to explore
docker create --name python-explorer cgr.dev/chainguard/python:latest-dev
docker export python-explorer > python-chainguard.tar

# Extract the contents
mkdir -p ~/python-image-contents
tar -xf python-chainguard.tar -C ~/python-image-contents

# Let's see what's in the image
echo "Files in root directory:"
ls -la ~/python-image-contents/

echo "Folders in the image:"
find ~/python-image-contents -type d | head -n 10

echo "Looking for common binaries:"
find ~/python-image-contents -type f -executable -name "bash" -o -name "sh" -o -name "dash" 2>/dev/null || echo "No shells found!"
find ~/python-image-contents -type f -executable -name "apt*" -o -name "dpkg" -o -name "yum" 2>/dev/null || echo "No package managers found!"

# Clean up
docker rm python-explorer
```{{exec}}

You'll notice that many traditional Linux utilities, shells, and package managers are missing. This is intentional - they're not needed to run your Python application and removing them reduces the attack surface.

## Understanding the Security Benefits

### 1. No Shell Access

Let's try to get a shell in the Chainguard image:

```bash
# Try to get a shell in the Chainguard Image (dev version)
docker run --rm -it cgr.dev/chainguard/python:latest-dev sh
```{{exec}}

In the dev version, you might get a minimal shell, but in the non-dev production version, you wouldn't. This is a security feature - if an attacker compromises your application, they can't get a shell to explore the system.

### 2. Reduced Attack Surface

Let's look at how the reduced attack surface impacts security scanning:

```bash
# Install trivy scanner
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.40.0

# Scan both images
echo "Scanning traditional image for vulnerabilities..."
trivy image python:3.11-slim --scanners vuln --severity HIGH,CRITICAL

echo "Scanning Chainguard image for vulnerabilities..."
trivy image cgr.dev/chainguard/python:latest-dev --scanners vuln --severity HIGH,CRITICAL
```{{exec}}

### 3. Examining User Permissions

Chainguard Images are designed to run as non-root by default:

```bash
# Check the default user in the Chainguard Image
docker inspect cgr.dev/chainguard/python:latest-dev | grep -A3 "User"

# Run a container and check who we're running as
docker run --rm cgr.dev/chainguard/python:latest-dev id
```{{exec}}

Running as a non-root user provides an additional layer of security.

### 4. Examining Other Chainguard Images

Let's pull and inspect a couple more Chainguard Images:

```bash
# Pull Chainguard nginx image
docker pull cgr.dev/chainguard/nginx:latest

# Pull Chainguard static image - a minimal image for static binaries
docker pull cgr.dev/chainguard/static:latest

# Compare sizes
docker images | grep -E "cgr.dev/chainguard|nginx"

# Try to run a shell in the static image
docker run --rm -it cgr.dev/chainguard/static:latest sh || echo "No shell available!"
```{{exec}}

The static image is particularly interesting as it's designed to run statically compiled binaries with almost nothing else in the container. This is perfect for Golang or Rust applications.

Now that we've explored existing Chainguard Images, let's move on to building our own application using a Chainguard Image as a base.