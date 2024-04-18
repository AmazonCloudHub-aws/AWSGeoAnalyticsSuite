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

## Backend bucket

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-backend-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "Terraform Backend Bucket"
    Environment = "Production"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}
