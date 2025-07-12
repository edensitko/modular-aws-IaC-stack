terraform {
  backend "s3" {
    bucket               = "terraform-backend-eden139"
    key                  = "terraform.tfstate"
    region               = "us-east-1"
    workspace_key_prefix = "env"
  }
}