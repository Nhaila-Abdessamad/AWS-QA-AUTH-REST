# AWS-QA-AUTH-REST# S3 Bucket Deployment with Terragrunt and Testing with Terratest

This repository demonstrates how to use Terragrunt to deploy a secure S3 bucket and Terratest to verify that the deployment meets security best practices.

## Features

The S3 bucket is configured with the following security features:

1. Default encryption using AES256
2. Block public access 
3. Versioning enabled
4. Tagged with environment and owner information

## Repository Structure

```
├── .github/
│   └── workflows/
│       └── terratest.yml (GitHub Actions workflow)
├── terragrunt/
│   ├── terragrunt.hcl (root configuration with dynamic region support)
│   └── environments/
│       └── dev/
│           └── s3/
│               ├── terragrunt.hcl (S3 bucket configuration)
│               └── terraform.tfvars (input variables)
├── terraform/
│   └── modules/
│       └── s3-bucket/
│           ├── main.tf (S3 bucket implementation)
│           ├── variables.tf (module variables)
│           └── outputs.tf (module outputs)
└── test/
    └── s3_bucket_test.go (Terratest test file)
```

## Tests

The Terratest file runs the following validations:

1. Confirms the S3 bucket exists
2. Verifies that the bucket has encryption enabled
3. Checks that the proper tags are applied
4. Verifies that public access is blocked (AWS S3 security best practice)
5. Confirms that versioning is enabled (AWS S3 security best practice)

## Running Locally

Prerequisites:
- Go 1.20+
- Terraform 1.5+
- Terragrunt 0.53+
- AWS CLI configured with appropriate credentials

To run the tests locally:

```bash
# Navigate to the test directory
cd test

# Initialize Go modules
go mod init github.com/yourusername/terraform-s3-bucket-test
go mod tidy

# Run the tests
go test -v ./...
```

## GitHub Actions

This repository includes a GitHub Actions workflow that:

1. Sets up the required dependencies (Go, Terraform, Terragrunt)
2. Configures AWS credentials
3. Initializes and validates the Terraform code
4. Runs the Terratest tests

To use the GitHub Actions workflow, you need to set up the following secrets in your repository:

- `AWS_ROLE_TO_ASSUME`: The ARN of an AWS IAM role that has permissions to create and manage S3 buckets

## Security Best Practices Implemented

Based on the [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html), this project implements:

1. Default encryption at rest using AES256
2. Block all public access to the bucket
3. Bucket versioning to protect against accidental deletion
4. Proper tagging for resource identification and management