terraform {
  backend "s3" {
    bucket         = "terraform-aws-lab-backend"
    key            = "state/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-aws-lab-state-lock"
    encrypt        = true
  }
}
