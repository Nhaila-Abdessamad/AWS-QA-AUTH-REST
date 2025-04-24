inputs = {
  # Base configuration
  bucket_prefix         = "secure-bucket"
  owner                 = "myself"
  
  # Security settings
  enable_secure_transport  = true
  enable_logging           = true
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
  
  # Encryption settings
  sse_algorithm            = "AES256"
  # kms_master_key_id      = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  # Versioning settings
  enable_versioning        = true
  versioning_status        = "Enabled"
  
  # Logging settings
  logging_target_prefix    = "s3-logs/"
  
  # Lifecycle configuration
  lifecycle_rules = [
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
  ]
  
  # Additional tags
  tags = {
    Project     = "S3SecurityDemo"
    CostCenter  = "DevOps"
    Compliance  = "GDPR"
    ManagedBy   = "Terragrunt"
  }
  
  # Dynamic region support
  region = "${get_env("AWS_REGION", "us-east-1")}"
}