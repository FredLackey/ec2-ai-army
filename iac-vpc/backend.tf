# Backend Configuration for Terraform State

terraform {
  backend "s3" {
    bucket         = "tfstate-ai-army-vpc"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-ai-army-vpc-locks"
    encrypt        = true
    profile        = "bh-fred-sandbox"
  }
}