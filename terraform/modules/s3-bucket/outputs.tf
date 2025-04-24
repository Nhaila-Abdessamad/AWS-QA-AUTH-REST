output "bucket_id" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.secure_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.secure_bucket.arn
}

output "bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = aws_s3_bucket.secure_bucket.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region where the bucket resides"
  value       = var.region
}

output "encryption_enabled" {
  description = "Whether server-side encryption is enabled"
  value       = true
}

output "encryption_algorithm" {
  description = "The server-side encryption algorithm used"
  value       = var.sse_algorithm
}

output "block_public_access_enabled" {
  description = "Whether block public access is enabled for the bucket"
  value       = var.block_public_acls && var.block_public_policy && var.ignore_public_acls && var.restrict_public_buckets
}

output "versioning_enabled" {
  description = "Whether versioning is enabled for the bucket"
  value       = var.enable_versioning ? var.versioning_status : "Disabled"
}

output "secure_transport_enforced" {
  description = "Whether HTTPS-only access is enforced"
  value       = var.enable_secure_transport
}

output "logging_enabled" {
  description = "Whether access logging is enabled"
  value       = var.enable_logging && var.logging_target_bucket != ""
}

output "logging_target_bucket" {
  description = "The target bucket for access logs"
  value       = var.enable_logging ? var.logging_target_bucket : null
}