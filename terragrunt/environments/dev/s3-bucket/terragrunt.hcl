include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../terraform/modules/s3-bucket"
}

dependency "log_bucket" {
  config_path = "../log-bucket"
  
  # Mock outputs for plan phase when the dependency is not yet created
  mock_outputs = {
    bucket_id = "mock-log-bucket"
  }
  skip_outputs = true
}

locals {
  # Parse the terraform.tfvars file
  config = read_terragrunt_config("terraform.tfvars")
  
  # Extract the bucket name with a default prefix based on environment
  environment   = get_env("TG_VAR_environment", "dev")
  region        = get_env("AWS_REGION", "us-east-1")
  bucket_prefix = local.config.inputs.bucket_prefix
  bucket_name   = "${local.bucket_prefix}-${local.environment}-${get_aws_account_id()}"

  # Additional security settings
  enable_secure_transport = local.config.inputs.enable_secure_transport
  enable_logging          = local.config.inputs.enable_logging
  sse_algorithm           = try(local.config.inputs.sse_algorithm, "AES256")
  enable_versioning       = try(local.config.inputs.enable_versioning, true)
  kms_key_id              = try(local.config.inputs.kms_master_key_id, null)
}

# Set inputs based on the configuration
inputs = {
  # Basic bucket configuration
  bucket_name     = local.bucket_name
  region          = local.region
  owner           = local.config.inputs.owner
  environment     = local.environment
  tags            = try(local.config.inputs.tags, {})
  
  # Encryption settings
  sse_algorithm     = local.sse_algorithm
  kms_master_key_id = local.kms_key_id
  
  # Security settings
  enable_secure_transport = local.enable_secure_transport
  block_public_acls       = try(local.config.inputs.block_public_acls, true)
  block_public_policy     = try(local.config.inputs.block_public_policy, true)
  ignore_public_acls      = try(local.config.inputs.ignore_public_acls, true)
  restrict_public_buckets = try(local.config.inputs.restrict_public_buckets, true)
  
  # Versioning settings
  enable_versioning = local.enable_versioning
  versioning_status = try(local.config.inputs.versioning_status, "Enabled")
  
  # Logging configuration
  enable_logging        = local.enable_logging
  logging_target_bucket = local.enable_logging ? dependency.log_bucket.outputs.bucket_id : ""
  logging_target_prefix = try(local.config.inputs.logging_target_prefix, "logs/")
  
  # Lifecycle rules
  lifecycle_rules = try(local.config.inputs.lifecycle_rules, [
    {
      id     = "archive-rule"
      status = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 365
      }
    }
  ])
}