#!/bin/bash

# Policy Audit Tool for FedRAMP Compliance
# This script checks the status of Kubernetes policy engines and their enforcement
# for FedRAMP compliance auditing purposes.

# Set output colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}Kubernetes Policy Audit Tool for FedRAMP Compliance${NC}"
echo "------------------------------------------------------"
echo "Running on: $(date)"
echo

# Check OPA Gatekeeper Installation
echo -e "${BOLD}1. OPA Gatekeeper Status${NC}"
if kubectl get ns gatekeeper-system &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} OPA Gatekeeper namespace exists"
  
  # Check if pods are running
  RUNNING_PODS=$(kubectl get pods -n gatekeeper-system -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
  if [[ -n $RUNNING_PODS ]]; then
    echo -e "  ${GREEN}✓${NC} OPA Gatekeeper pods are running"
    echo "  Pods: $RUNNING_PODS"
  else
    echo -e "  ${RED}✗${NC} OPA Gatekeeper pods are not running"
  fi
  
  # Check constraint templates
  TEMPLATES=$(kubectl get constrainttemplates -o jsonpath='{.items[*].metadata.name}')
  if [[ -n $TEMPLATES ]]; then
    echo -e "  ${GREEN}✓${NC} OPA Gatekeeper constraint templates found: $(echo $TEMPLATES | wc -w)"
    echo "  Templates: $TEMPLATES"
  else
    echo -e "  ${YELLOW}!${NC} No OPA Gatekeeper constraint templates found"
  fi
  
  # Check constraints
  CONSTRAINTS=$(kubectl get constraints --all-namespaces -o jsonpath='{.items[*].metadata.name}')
  if [[ -n $CONSTRAINTS ]]; then
    echo -e "  ${GREEN}✓${NC} OPA Gatekeeper constraints found: $(echo $CONSTRAINTS | wc -w)"
    echo "  Constraints: $CONSTRAINTS"
    
    # Check for violations
    for CONSTRAINT in $CONSTRAINTS; do
      VIOLATIONS=$(kubectl get constraint $CONSTRAINT -o jsonpath='{.status.totalViolations}' 2>/dev/null)
      if [[ -z $VIOLATIONS ]]; then
        VIOLATIONS="unknown"
      fi
      if [[ $VIOLATIONS == "0" || $VIOLATIONS == "unknown" ]]; then
        echo -e "    ${GREEN}✓${NC} $CONSTRAINT: $VIOLATIONS violations"
      else
        echo -e "    ${YELLOW}!${NC} $CONSTRAINT: ${YELLOW}$VIOLATIONS violations${NC}"
      fi
    done
  else
    echo -e "  ${YELLOW}!${NC} No OPA Gatekeeper constraints found"
  fi
else
  echo -e "  ${YELLOW}!${NC} OPA Gatekeeper not installed"
fi

echo

# Check Kyverno Installation
echo -e "${BOLD}2. Kyverno Status${NC}"
if kubectl get ns kyverno &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Kyverno namespace exists"
  
  # Check if pods are running
  RUNNING_PODS=$(kubectl get pods -n kyverno -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
  if [[ -n $RUNNING_PODS ]]; then
    echo -e "  ${GREEN}✓${NC} Kyverno pods are running"
    echo "  Pods: $RUNNING_PODS"
  else
    echo -e "  ${RED}✗${NC} Kyverno pods are not running"
  fi
  
  # Check policies
  POLICIES=$(kubectl get cpol -o jsonpath='{.items[*].metadata.name}')
  if [[ -n $POLICIES ]]; then
    echo -e "  ${GREEN}✓${NC} Kyverno policies found: $(echo $POLICIES | wc -w)"
    echo "  Policies: $POLICIES"
    
    # Check enforcement action for each policy
    for POLICY in $POLICIES; do
      ENFORCEMENT=$(kubectl get cpol $POLICY -o jsonpath='{.spec.validationFailureAction}')
      if [[ $ENFORCEMENT == "enforce" ]]; then
        echo -e "    ${GREEN}✓${NC} $POLICY: ${GREEN}$ENFORCEMENT${NC}"
      else
        echo -e "    ${YELLOW}!${NC} $POLICY: ${YELLOW}$ENFORCEMENT${NC} (not enforcing)"
      fi
    done
    
    # Check for policy reports
    if kubectl get policyreport &>/dev/null; then
      REPORTS=$(kubectl get policyreport --all-namespaces -o json | jq -r '.items | length')
      PASS=$(kubectl get policyreport --all-namespaces -o json | jq -r '.items[].results[] | select(.result=="pass") | .result' | wc -l)
      FAIL=$(kubectl get policyreport --all-namespaces -o json | jq -r '.items[].results[] | select(.result=="fail") | .result' | wc -l)
      WARN=$(kubectl get policyreport --all-namespaces -o json | jq -r '.items[].results[] | select(.result=="warn") | .result' | wc -l)
      
      echo -e "  ${GREEN}✓${NC} Kyverno policy reports found: $REPORTS"
      echo -e "    ${GREEN}Pass:${NC} $PASS, ${RED}Fail:${NC} $FAIL, ${YELLOW}Warn:${NC} $WARN"
    else
      echo -e "  ${YELLOW}!${NC} No Kyverno policy reports found"
    fi
  else
    echo -e "  ${YELLOW}!${NC} No Kyverno policies found"
  fi
else
  echo -e "  ${YELLOW}!${NC} Kyverno not installed"
fi

echo

# FedRAMP Control Coverage Analysis
echo -e "${BOLD}3. FedRAMP Control Coverage Analysis${NC}"

# Define FedRAMP controls covered by our policies
declare -A CONTROLS
CONTROLS["CM-8"]="Component Inventory"
CONTROLS["AC-6"]="Least Privilege"
CONTROLS["CM-7"]="Least Functionality"
CONTROLS["SC-6"]="Resource Availability"
CONTROLS["SC-7"]="Boundary Protection"

# Initialize counters
TOTAL_CONTROLS=${#CONTROLS[@]}
COVERED_CONTROLS=0

# Check coverage
for CONTROL in "${!CONTROLS[@]}"; do
  DESCRIPTION=${CONTROLS[$CONTROL]}
  COVERED=false
  
  # Check OPA Gatekeeper constraints for this control
  if [[ $CONTROL == "CM-8" && $(kubectl get constraint require-security-labels 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="OPA Gatekeeper: require-security-labels"
  elif [[ $CONTROL == "AC-6" && $(kubectl get constraint prevent-privileged-containers 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="OPA Gatekeeper: prevent-privileged-containers"
  elif [[ $CONTROL == "CM-7" && $(kubectl get constraint allowed-image-repos 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="OPA Gatekeeper: allowed-image-repos"
  elif [[ $CONTROL == "SC-6" && $(kubectl get constraint require-resource-limits 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="OPA Gatekeeper: require-resource-limits"
  fi
  
  # Check Kyverno policies for this control
  if [[ $CONTROL == "CM-8" && $(kubectl get cpol require-security-labels 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="${IMPLEMENTATION:-}${IMPLEMENTATION:+, }Kyverno: require-security-labels"
  elif [[ $CONTROL == "AC-6" && $(kubectl get cpol restrict-privileged-containers 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="${IMPLEMENTATION:-}${IMPLEMENTATION:+, }Kyverno: restrict-privileged-containers"
  elif [[ $CONTROL == "CM-7" && $(kubectl get cpol allowed-image-registries 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="${IMPLEMENTATION:-}${IMPLEMENTATION:+, }Kyverno: allowed-image-registries"
  elif [[ $CONTROL == "SC-6" && $(kubectl get cpol require-resource-limits 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="${IMPLEMENTATION:-}${IMPLEMENTATION:+, }Kyverno: require-resource-limits"
  elif [[ $CONTROL == "SC-7" && $(kubectl get cpol disallow-host-namespaces 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="Kyverno: disallow-host-namespaces"
  elif [[ $CONTROL == "AC-6" && $(kubectl get cpol disallow-capabilities 2>/dev/null) ]]; then
    COVERED=true
    IMPLEMENTATION="${IMPLEMENTATION:-}${IMPLEMENTATION:+, }Kyverno: disallow-capabilities"
  fi
  
  # Output results
  if [[ $COVERED == true ]]; then
    echo -e "  ${GREEN}✓${NC} $CONTROL: $DESCRIPTION"
    echo -e "    Implemented by: $IMPLEMENTATION"
    ((COVERED_CONTROLS++))
  else
    echo -e "  ${RED}✗${NC} $CONTROL: $DESCRIPTION"
    echo -e "    Not implemented by any policy"
  fi
done

# Calculate coverage percentage
COVERAGE_PCT=$((COVERED_CONTROLS * 100 / TOTAL_CONTROLS))

echo
echo -e "${BOLD}FedRAMP Policy Control Coverage:${NC} $COVERED_CONTROLS/$TOTAL_CONTROLS ($COVERAGE_PCT%)"

if [[ $COVERAGE_PCT -eq 100 ]]; then
  echo -e "${GREEN}All monitored FedRAMP controls are covered by policies${NC}"
elif [[ $COVERAGE_PCT -ge 80 ]]; then
  echo -e "${YELLOW}Most monitored FedRAMP controls are covered, but some are missing${NC}"
else
  echo -e "${RED}Significant gaps exist in FedRAMP control coverage${NC}"
fi

echo
echo "Audit completed at $(date)"
echo "------------------------------------------------------"