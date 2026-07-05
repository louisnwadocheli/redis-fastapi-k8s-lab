terraform {
  backend "s3" {
    bucket         = "redis-fastapi-lab-tfstate-louis-2026"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "redis-fastapi-lab-terraform-locks"
    encrypt        = true
  }
}
