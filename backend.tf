terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "path/to/your/statefile.tfstate"
    region         = "us-east-1"
    dynamodb_table = "your-lock-table"
  }
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "terraform-state"
  acl    = "private" 
}