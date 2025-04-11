# AWS FedRAMP Compliance Checklist

This document provides a reference for key FedRAMP controls applicable to AWS environments and how to implement them.

## Access Control (AC)

### AC-2: Account Management

**AWS Services**: IAM

**Implementation Requirements**:
- [ ] Implement automated account management processes
- [ ] Define and document account types and authorization levels
- [ ] Establish conditions for group/role membership
- [ ] Specify authorized users, group memberships, and access authorizations
- [ ] Require administrative approval for account creation
- [ ] Configure automated audit for account management actions
- [ ] Remove temporary accounts automatically
- [ ] Disable inactive accounts automatically
- [ ] Create, enable, modify, disable, and remove accounts in accordance with organization policies

**AWS Best Practices**:
- Use IAM to create and manage user accounts
- Implement password policies for IAM users
- Use IAM Access Analyzer to review access
- Enable AWS Config to track account changes
- Implement automated account termination processes

### AC-3: Access Enforcement

**AWS Services**: IAM, S3, KMS

**Implementation Requirements**:
- [ ] Enforce approved authorizations for logical access
- [ ] Enforce access control policies at the system level
- [ ] Implement role-based access control

**AWS Best Practices**:
- Use IAM policies to enforce access controls
- Implement S3 bucket policies that deny public access
- Use VPC endpoints with policies to control service access
- Implement resource-based policies where applicable

### AC-6: Least Privilege

**AWS Services**: IAM

**Implementation Requirements**:
- [ ] Assign users only the access needed to perform their job duties
- [ ] Regularly audit privileged accounts and functions
- [ ] Explicitly authorize access to security functions
- [ ] Restrict privileged accounts to privileged users
- [ ] Prevent non-privileged users from executing privileged functions

**AWS Best Practices**:
- Use IAM policy conditions to further restrict access
- Implement Permission Boundaries to limit maximum permissions
- Avoid using wildcard (*) permissions in IAM policies
- Use Service Control Policies (SCPs) in AWS Organizations
- Review IAM Access Advisor data regularly

## Audit and Accountability (AU)

### AU-2: Audit Events

**AWS Services**: CloudTrail, CloudWatch

**Implementation Requirements**:
- [ ] Determine what events are auditable within the system
- [ ] Coordinate audit event selection with security monitoring needs
- [ ] Review and update audited events periodically
- [ ] Provide justification for events not selected for auditing

**AWS Best Practices**:
- Enable CloudTrail for all regions
- Log data and management events
- Configure CloudWatch alarms for significant events
- Use CloudTrail Insights for unusual API activity detection
- Implement AWS Config rules for configuration audit

### AU-9: Protection of Audit Information

**AWS Services**: CloudTrail, S3, KMS

**Implementation Requirements**:
- [ ] Protect audit information from unauthorized access, modification, and deletion
- [ ] Limit access to audit logs to authorized personnel
- [ ] Implement backup of audit records to separate physical systems

**AWS Best Practices**:
- Enable CloudTrail log file validation
- Configure S3 bucket encryption for CloudTrail logs
- Enable S3 bucket versioning for CloudTrail logs
- Restrict S3 bucket policies for CloudTrail buckets
- Configure S3 object lock for compliance mode retention

## Configuration Management (CM)

### CM-7: Least Functionality

**AWS Services**: Security Groups, NACLs, Systems Manager

**Implementation Requirements**:
- [ ] Configure the system to provide only essential capabilities
- [ ] Prohibit or restrict the use of functions, ports, protocols, or services as defined
- [ ] Review the system periodically to remove unnecessary functions and services

**AWS Best Practices**:
- Configure restrictive security groups and NACLs
- Use AWS Config to check for non-compliant configurations
- Implement Systems Manager State Manager for consistent configurations
- Use VPC Flow Logs to monitor network traffic
- Implement security group usage audit

### CM-8: Information System Component Inventory

**AWS Services**: AWS Config, Systems Manager, Resource Groups

**Implementation Requirements**:
- [ ] Develop and document an inventory of system components
- [ ] Update the inventory as components are installed, removed, or updated
- [ ] Review and update the inventory periodically

**AWS Best Practices**:
- Enable AWS Config to maintain resource inventory
- Use resource tagging for asset identification
- Implement Systems Manager Inventory for managed instances
- Use AWS Config Aggregators for multi-account/region inventory
- Generate periodic inventory reports

## System and Communications Protection (SC)

### SC-7: Boundary Protection

**AWS Services**: VPC, Security Groups, NACLs, WAF, Shield

**Implementation Requirements**:
- [ ] Monitor and control communications at system boundaries
- [ ] Implement subnetworks for publicly accessible components
- [ ] Connect to external networks or systems only through managed interfaces
- [ ] Deny network traffic by default and allow by exception

**AWS Best Practices**:
- Implement private subnets for sensitive resources
- Use VPC endpoints for AWS service access
- Configure WAF for web application protection
- Implement AWS Shield for DDoS protection
- Use Security Groups and NACLs to segment network traffic

### SC-13: Cryptographic Protection

**AWS Services**: KMS, S3, EBS, RDS

**Implementation Requirements**:
- [ ] Implement FIPS-validated cryptography for information protection
- [ ] Use cryptography in accordance with applicable laws and standards

**AWS Best Practices**:
- Use AWS KMS for key management
- Enable default encryption for S3 buckets
- Use encrypted EBS volumes
- Enable encryption for RDS databases
- Configure TLS for data in transit
- Use AWS Certificate Manager for TLS certificates