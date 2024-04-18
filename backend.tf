terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
