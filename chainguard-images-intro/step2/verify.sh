#!/bin/bash

# Check if the Python app file was created
if [ -f ~/python-app/app.py ]; then
  exit 0
else
  echo "Please complete all the commands in Step 2"
  exit 1
fi