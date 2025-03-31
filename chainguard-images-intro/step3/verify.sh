#!/bin/bash

# Check if the Go app was built
if [ -f ~/go-app/Dockerfile ]; then
  exit 0
else
  echo "Please complete all the commands in Step 3"
  exit 1
fi