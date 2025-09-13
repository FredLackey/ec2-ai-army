terraform {
  backend "s3" {
    bucket         = "tfstate-ai-army-instances"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-ai-army-instances-locks"
    encrypt        = true
    profile        = "bh-fred-sandbox"
  }
}