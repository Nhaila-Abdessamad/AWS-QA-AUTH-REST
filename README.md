# S3 Secure Bucket Module

This repository contains a secure S3 bucket Terraform module with comprehensive test coverage using Terragrunt for configuration management and Terratest for integration testing.

## Table of Contents

1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Architecture](#architecture)
4. [Security Features](#security-features)
5. [Configuration](#configuration)
   - [Root Terragrunt Configuration](#root-terragrunt-configuration)
   - [Module-specific Terragrunt Configuration](#module-specific-terragrunt-configuration)
   - [Terraform Variables](#terraform-variables)
6. [Testing](#testing)
   - [Testing Strategy](#testing-strategy)
   - [Test Execution Flow](#test-execution-flow)
   - [Test Scenarios](#test-scenarios)
7. [CI/CD Integration](#cicd-integration)
8. [Best Practices](#best-practices)
   - [Infrastructure as Code](#infrastructure-as-code)
   - [Security](#security)
   - [Testing](#testing-best-practices)
   - [Configuration Management](#configuration-management)
9. [Terraform Framework Concepts](#terraform-framework-concepts)
   - [Terragrunt](#terragrunt)
   - [Terratest](#terratest)
   - [Terraform Modules](#terraform-modules)
10. [Expanding the Project](#expanding-the-project)
11. [Troubleshooting](#troubleshooting)

## Overview

This project demonstrates how to create a secure S3 bucket in AWS with proper access controls, encryption, logging, and lifecycle management. It uses Terragrunt for configuration management and Terratest for automated integration testing. The module follows AWS security best practices and includes comprehensive test coverage.

## Repository Structure

```
.
├── terraform/
│   └── modules/
│       └── s3-bucket/
│           ├── main.tf            # Main module resources
│           ├── variables.tf       # Module input variables
│           └── outputs.tf         # Module outputs
├── terragrunt/
│   ├── terragrunt.hcl             # Root configuration
│   └── environments/
│       └── dev/
│           ├── s3-bucket/
│           │   ├── terragrunt.hcl # Module-specific configuration
│           │   └── terraform.tfvars # Module-specific variables
│           └── log-bucket/
│               └── ...
├── test/
│   └── s3_bucket_test.go          # Integration tests
└── .github/workflows/
    └── run_s3_test.yml            # CI/CD workflow
```

## Architecture

The architecture consists of:

1. **Terraform Module**: Core implementation of the S3 bucket with all security features
2. **Terragrunt Layer**: Configuration management for different environments
3. **Terratest Layer**: Integration tests to verify the deployed infrastructure
4. **CI/CD Pipeline**: Automated testing on pull requests and merges

## Security Features

The S3 bucket module implements the following security features:

- **Server-Side Encryption**: AES256 or KMS encryption for data at rest
- **Public Access Blocking**: Complete lockdown of public access
- **HTTPS Enforcement**: Bucket policy requiring secure transport
- **Versioning**: Object versioning to prevent accidental deletion
- **Access Logging**: Optional logging to a separate bucket
- **Lifecycle Rules**: Automatic transition to cost-effective storage classes and expiration

## Configuration

### Root Terragrunt Configuration

The root `terragrunt.hcl` file provides:

- Remote state configuration using S3 backend
- AWS provider configuration
- Environment-based variables and tags
- Common configuration for all modules

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "terragrunt-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Common variables for all modules
inputs = {
  environment = local.environment
  region      = local.aws_region
  tags        = local.common_tags
}
```

### Module-specific Terragrunt Configuration

The S3 bucket-specific `terragrunt.hcl` file:

- Includes the root configuration
- Points to the Terraform module
- Defines dependencies (like the log bucket)
- Processes module-specific variables

```hcl
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../terraform/modules/s3-bucket"
}

dependency "log_bucket" {
  config_path = "../log-bucket"
}

# Module-specific inputs
inputs = {
  bucket_name     = local.bucket_name
  enable_logging  = local.enable_logging
  # ... other inputs
}
```

### Terraform Variables

Variables are defined in:

1. **terraform.tfvars**: Default values for the module
2. **Environment variables**: Runtime overrides (AWS_REGION, TG_VAR_environment)
3. **Direct overrides**: From Terratest or command-line arguments

## Testing

### Testing Strategy

The testing strategy uses integration tests to verify the actual behavior of deployed resources:

1. **Resource Creation**: Verify the bucket is created with the correct configuration
2. **Security Verification**: Ensure all security features are properly enabled
3. **Cleanup**: Destroy all resources after testing

### Test Execution Flow

1. **Setup Phase**:
   - Generate a unique bucket name for testing
   - Configure Terragrunt options
   - Set environment variables

2. **Deployment Phase**:
   - Run `terragrunt init` and `terragrunt apply`
   - Create the actual AWS resources

3. **Verification Phase**:
   - Verify bucket existence
   - Check encryption configuration
   - Validate tags
   - Confirm public access blocking
   - Verify versioning
   - Check secure transport policy

4. **Cleanup Phase**:
   - Run `terragrunt destroy` to remove test resources

### Test Scenarios

The test covers six key scenarios:

1. **BucketExists**: The bucket is successfully created
2. **BucketIsEncrypted**: Server-side encryption is properly configured
3. **BucketHasCorrectTags**: Required tags are applied
4. **BucketBlocksPublicAccess**: All public access blocking settings are enabled
5. **BucketHasVersioningEnabled**: Versioning is properly enabled
6. **BucketEnforcesSecureTransport**: HTTPS is required by bucket policy

## CI/CD Integration

The GitHub workflow (`run_s3_test.yml`) automates testing:

1. **Environment Setup**:
   - Set up Go, Terraform, and Terragrunt
   - Configure AWS credentials

2. **Static Validation**:
   - Validate the Terraform module

3. **Integration Testing**:
   - Run the Terratest test suite
   - Verify all assertions pass

## Best Practices

### Infrastructure as Code

- **Modular Design**: Separation of concerns between S3 module and configuration
- **DRY Principle**: Root configuration avoids repetition
- **Variable Defaults**: Sensible defaults with override capability
- **Dynamic Values**: Calculated values based on environment and account

### Security

- **Defense in Depth**: Multiple security features work together
- **Principle of Least Privilege**: Minimal permissions approach
- **Encryption by Default**: All data is encrypted at rest
- **HTTPS Enforcement**: All traffic must be encrypted in transit
- **No Public Access**: Public access blocked by default

### Testing Best Practices

- **Isolated Tests**: Each test has a unique bucket name
- **Comprehensive Checks**: All security aspects are verified
- **Proper Cleanup**: All test resources are destroyed after testing
- **CI Integration**: Tests run automatically on code changes

### Configuration Management

- **Environment Separation**: Configuration separated by environment
- **Dependency Management**: Clear dependencies between modules
- **Configuration Override**: Environment-specific values override defaults
- **Secret Management**: Sensitive values handled through environment variables

## Terraform Framework Concepts

### Terragrunt

**Key Takeaways:**

1. **Configuration Inheritance**: Root and child configurations create a DRY structure
2. **Remote State Management**: Consistent state configuration across modules
3. **Dependency Management**: Clear dependencies between modules
4. **Environmental Awareness**: Configuration based on environment context
5. **Provider Generation**: Common provider configuration across modules

### Terratest

**Key Takeaways:**

1. **Integration Testing**: Tests actual deployed resources
2. **Infrastructure Lifecycle**: Handles complete create-validate-destroy cycle
3. **Parallel Execution**: Top-level tests can run in parallel
4. **AWS SDK Integration**: Direct validation of AWS resources
5. **Subtest Organization**: Logical grouping of verification steps

### Terraform Modules

**Key Takeaways:**

1. **Resource Encapsulation**: Logical grouping of related resources
2. **Input Variables**: Control module behavior through variables
3. **Output Values**: Expose important resource attributes
4. **Dynamic Resources**: Conditional resource creation based on inputs
5. **Security Best Practices**: Built-in security features

## Expanding the Project

To expand this project:

1. **Additional Resource Types**:
   - Add more AWS resource modules (RDS, EC2, ECS)
   - Apply the same testing approach to each module

2. **Cross-Account Deployment**:
   - Adapt Terragrunt configuration for multi-account setups
   - Add assume role capabilities for cross-account access

3. **Enhanced Testing**:
   - Add policy validation tests
   - Test performance aspects of resources
   - Add failure scenario testing

4. **Advanced Features**:
   - Object lock for compliance
   - Cross-region replication
   - Intelligent Tiering configuration

5. **Security Extensions**:
   - VPC endpoint support
   - Advanced bucket policies
   - Service control policies integration

## Troubleshooting

Common issues and solutions:

1. **AWS Credential Issues**:
   - Ensure AWS credentials are properly configured

2. **Terragrunt Dependency Errors**:
   - Verify mock outputs for dependencies
   - Ensure dependency paths are correct

4. **CI Pipeline Failures**:
   - Check GitHub secrets for AWS credentials
   - Verify timeout settings for longer tests

