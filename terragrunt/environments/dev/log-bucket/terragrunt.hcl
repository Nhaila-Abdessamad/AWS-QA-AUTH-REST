include {
  path = find_in_parent_folders()
}

# This is just a mock module to satisfy the dependency
# It will not actually be applied during testing
terraform {
  source = "../../../terraform/modules/s3-bucket"
}

inputs = {
  bucket_name = "mock-logging-bucket"
  owner       = "terratest"
}