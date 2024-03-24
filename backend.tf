terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "path/to/your/statefile.tfstate"
    region         = "your-aws-region"
    dynamodb_table = "your-lock-table"  # Optional for state locking
  }
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "terraform-state"
  acl    = "private"  # Adjust as needed
  # Add other bucket configurations as needed
}
