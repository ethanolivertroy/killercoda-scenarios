#!/bin/bash

# Check if Python image was pulled
if docker images | grep -q "cgr.dev/chainguard/python"; then
  exit 0
else
  echo "Please complete all the commands in Step 1"
  exit 1
fi