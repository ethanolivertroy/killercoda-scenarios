# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure
This repository contains Killercoda scenarios focused on FedRAMP security compliance for Kubernetes and service mesh environments.

## Commands

### Verification
- Verify shell scripts: `shellcheck *.sh`
- Validate YAML: `yamllint *.yaml` or `kubectl apply --dry-run=client -f <file.yaml>`
- Run a specific verification script: `./step1/verify.sh`

### Running Scripts
- Run audit tools: `bash assets/audit-tool.sh`

## Code Style Guidelines

### Shell Scripts
- Use `#!/bin/bash` shebang
- Add descriptive comments for functions
- Use meaningful variable names in UPPER_SNAKE_CASE
- Follow POSIX standards for compatibility
- Use defensive programming (`set -e`, error checking)

### YAML Files
- Use 2-space indentation
- Add descriptive comments with # for complex sections
- Group related resources in the same file
- Follow Kubernetes best practices for resource definitions

### Naming Conventions
- Scripts: kebab-case.sh (e.g., `audit-tool.sh`)
- YAML files: kebab-case.yaml (e.g., `compliance-checklist.yaml`)
- Directory structure: lowercase with hyphens (e.g., `kubernetes-fedramp-audit`)