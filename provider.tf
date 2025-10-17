# Define provider block for AWS
variable "use_localstack" {
  type    = bool
  default = false
}

provider "aws" {
  region = var.use_localstack ? "us-east-1" : "us-east-1"

  # When running against LocalStack (CI job), Terraform will use the endpoints set via
  # the localstack_provider.tf file that is created in the CI job. The provider settings
  # here rely on environment variables or explicit endpoints file written by CI.
  # Keep default behavior unchanged for real AWS usage.
}