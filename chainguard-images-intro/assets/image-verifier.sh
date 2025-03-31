#!/bin/bash
set -e

# This is a more complex example of verifying Chainguard images
# for potential inclusion in a CI/CD pipeline

IMAGE="$1"
THRESHOLD="${2:-CRITICAL}"  # Default to blocking only CRITICAL vulnerabilities

echo "🔍 Verifying Chainguard image: $IMAGE"
echo "🛡️  Vulnerability threshold: $THRESHOLD"

# Check if cosign is installed
if ! command -v cosign &> /dev/null; then
  echo "❌ cosign not found, installing..."
  curl -sLO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
  chmod +x cosign-linux-amd64
  mv cosign-linux-amd64 /usr/local/bin/cosign
fi

# Check if trivy is installed
if ! command -v trivy &> /dev/null; then
  echo "❌ trivy not found, installing..."
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.40.0
fi

# Verify signature
echo "🔐 Verifying image signature..."
if cosign verify "$IMAGE"; then
  echo "✅ Signature verification PASSED"
else
  echo "❌ Signature verification FAILED"
  exit 1
fi

# Check for SBOM
echo "📋 Verifying SBOM attestation..."
if cosign verify-attestation --type spdx "$IMAGE" > /dev/null; then
  echo "✅ SBOM attestation PASSED"
else
  echo "⚠️ SBOM attestation missing or invalid (may be expected for some images)"
fi

# Check for vulnerabilities
echo "🔎 Scanning for vulnerabilities..."
SCAN_THRESHOLD="--severity $THRESHOLD"
if [ "$THRESHOLD" = "ANY" ]; then
  SCAN_THRESHOLD=""
fi

if trivy image $SCAN_THRESHOLD --exit-code 1 "$IMAGE"; then
  echo "✅ Vulnerability scan PASSED"
else
  echo "❌ Vulnerability scan FAILED - $THRESHOLD vulnerabilities found"
  exit 1
fi

echo "✅ All checks PASSED for $IMAGE"
echo "🔒 Image is verified and can be used in production"