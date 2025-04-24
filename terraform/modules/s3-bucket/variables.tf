variable "region" {
  description = "AWS region where the S3 bucket will be created"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "myself"
}

variable "tags" {
  description = "Additional tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "enable_secure_transport" {
  description = "Whether to enforce HTTPS for all requests"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Whether to enable bucket access logging"
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "Target bucket for access logs"
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Prefix for log objects in the target bucket"
  type        = string
  default     = "log/"
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules to apply to the bucket"
  type = list(object({
    id     = string
    status = string
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })))
    expiration = optional(object({
      days = number
    }))
  }))
  default = []
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  type        = string
  default     = "AES256"
}

variable "kms_master_key_id" {
  description = "The AWS KMS master key ID used for the SSE-KMS encryption if using KMS"
  type        = string
  default     = null
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Whether to enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "versioning_status" {
  description = "Versioning state of the bucket (Enabled, Suspended, or Disabled)"
  type        = string
  default     = "Enabled"
}