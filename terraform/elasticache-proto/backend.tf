terraform {
  backend "s3" {
    bucket = "portfolio-dev-1brk-tfstate-bucket"
    key = "terraform/redis"
    workspace_key_prefix = "env"
    region = "us-east-1"
    encrypt = true
  }
}