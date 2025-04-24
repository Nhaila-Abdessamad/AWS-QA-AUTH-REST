remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "terragrunt-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

locals {
  # Extract environment from the path
  path_components = compact(split("/", path_relative_to_include()))
  environment     = local.path_components[0]
  
  # Get region from environment variable with fallback to default
  aws_region      = get_env("AWS_REGION", "us-east-1")
  
  # Common tags for all resources
  common_tags = {
    ManagedBy   = "Terragrunt"
    Environment = local.environment
  }
}

# Configure root level variables that all resources can inherit
inputs = {
  environment = local.environment
  region      = local.aws_region
  tags        = local.common_tags
}