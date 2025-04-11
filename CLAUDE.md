# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure
This repository contains Killercoda scenarios focused on FedRAMP security compliance for Kubernetes and service mesh environments.

Each scenario follows the Killercoda structure:
- `index.json` - Main configuration file defining steps and assets
- `intro.md` - Introduction content shown at start of scenario
- `finish.md` - Conclusion content shown at end of scenario
- `step1/text.md`, `step2/text.md`, etc. - Content for each step
- `step1/verify.sh`, `step2/verify.sh`, etc. - Verification scripts
- `assets/` - Directory containing files provided to the scenario

## Commands

### Verification
- Verify shell scripts: `shellcheck *.sh`
- Validate YAML: `yamllint *.yaml` or `kubectl apply --dry-run=client -f <file.yaml>`
- Run a specific verification script: `./step1/verify.sh`

### Running Scripts
- Run audit tools: `bash assets/audit-tool.sh`

## Killercoda-specific Guidelines

### index.json Structure
- Always include title, description, intro, steps, and finish sections
- Steps must have title and text properties
- Assets must specify target and chmod (if executable)
- Use supported imageid values for backend (e.g., "kubernetes-kubeadm-2nodes")

### Markdown Content
- Use `{{exec}}` suffix for command blocks to make them executable
- Use `{{copy}}` suffix to make text blocks copyable
- Use standard Markdown formatting (headers, lists, code blocks)
- Keep step content focused and concise

### Verification Scripts
- Verification scripts (`verify.sh`) should exit with code 0 for success or non-zero for failure
- Must be idempotent and reliable
- Should include clear error messages for failures
- Consider resource constraints of the learning environment

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