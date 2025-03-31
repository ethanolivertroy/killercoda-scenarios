# Understanding Chainguard Images

In this step, we'll explore what makes Chainguard Images different from traditional container images and why they provide security benefits.

## What are Distroless Images?

Distroless images contain only your application and its runtime dependencies. They do not contain package managers, shells, or other programs you might find in a standard Linux distribution. This significantly reduces the attack surface of your container.

Let's compare the sizes of a traditional image vs. a Chainguard Image:

```bash
# Pull a traditional Python image
docker pull python:3.11-slim
# Pull a Chainguard Python image
docker pull cgr.dev/chainguard/python:latest-dev
# Compare sizes
docker images | grep python
```{{exec}}

You should notice that the Chainguard image is significantly smaller.

## Key Benefits of Chainguard Images

Chainguard Images offer several key benefits:

### 1. Small Attack Surface

Fewer components means fewer potential vulnerabilities:

```bash
# Let's check how many packages are in a traditional image
docker run --rm python:3.11-slim sh -c "apt list --installed | wc -l"
# Let's check the same for a Chainguard image
docker run --rm cgr.dev/chainguard/python:latest-dev sh -c "apk info 2>/dev/null | wc -l" || echo "Shell not available - that's the point!"
```{{exec}}

The absence of a shell in production Chainguard images is intentional - no shell means attackers can't execute shell commands if they compromise your application.

### 2. Up-to-Date Dependencies

Chainguard Images are rebuilt daily with the latest security patches:

```bash
# Check when the image was built
docker inspect cgr.dev/chainguard/python:latest-dev | grep Created
```{{exec}}

### 3. Verifiable Supply Chain

Chainguard Images come with attestations about how they were built:

```bash
# Install cosign for verification
curl -sLO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Verify the signature of the image
cosign verify cgr.dev/chainguard/python:latest-dev
```{{exec}}

### 4. Software Bill of Materials (SBOM)

Chainguard Images include a complete list of all components in the image:

```bash
# Install syft to read SBOMs
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Generate SBOM for the Chainguard image
syft cgr.dev/chainguard/python:latest-dev -o json | jq '.artifacts | length'
```{{exec}}

## Comparing Security Posture

Let's check for vulnerabilities in both images:

```bash
# Install grype for vulnerability scanning
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Scan the traditional image
echo "Scanning traditional Python image:"
grype python:3.11-slim --output table 

# Scan the Chainguard image
echo "Scanning Chainguard Python image:"
grype cgr.dev/chainguard/python:latest-dev --output table
```{{exec}}

Notice the difference in the number of vulnerabilities found. Chainguard Images are designed to have minimal or zero known vulnerabilities.

Let's move on to the next step, where we'll run and inspect Chainguard Images in more detail.