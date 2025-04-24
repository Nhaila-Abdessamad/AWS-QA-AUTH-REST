# Provider is handled by Terragrunt's generated provider.tf

resource "aws_s3_bucket" "secure_bucket" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      environment = var.environment
      owner       = var.owner
    }
  )
}

# Enable default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_master_key_id : null
    }
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = var.versioning_status
  }
}

# Apply bucket policy for additional security 
resource "aws_s3_bucket_policy" "secure_policy" {
  count  = var.enable_secure_transport ? 1 : 0
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Enable bucket logging if configured
resource "aws_s3_bucket_logging" "logging" {
  count         = var.enable_logging && var.logging_target_bucket != "" ? 1 : 0
  bucket        = aws_s3_bucket.secure_bucket.id
  target_bucket = var.logging_target_bucket
  target_prefix = "${var.logging_target_prefix}${var.bucket_name}/"
}

# Apply lifecycle rules if configured
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_rules" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.secure_bucket.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }
}