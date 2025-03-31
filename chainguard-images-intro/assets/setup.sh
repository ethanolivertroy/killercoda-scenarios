#!/bin/bash

# This script will run at environment startup
# Install Docker if not available
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  apt-get update
  apt-get install -y docker.io
  systemctl enable docker
  systemctl start docker
fi

# Pull images in advance to speed up the scenario
docker pull python:3.11-slim &
docker pull cgr.dev/chainguard/python:latest-dev &
docker pull cgr.dev/chainguard/nginx:latest &
docker pull cgr.dev/chainguard/static:latest &
docker pull cgr.dev/chainguard/go:latest &

# Wait for image pulls to complete
wait

echo "Environment setup complete!"