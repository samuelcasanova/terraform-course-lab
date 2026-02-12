terraform {
  required_version = ">= 1.0.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Access the infrastructure state
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "terraform-aws-lab-backend"
    key    = "state/terraform.tfstate"
    region = "eu-west-3"
  }
}

provider "kubernetes" {
  host     = "https://${data.terraform_remote_state.infra.outputs.ec2_public_ip}:6443"
  # Note: You might need to make sure 'k8s_token' is an output in infra/outputs.tf or similar
  # For now, I'll assume we can get it from local state or variables if needed.
  # But since we moved everything, we should make it an output in infra.

  # Placeholder for token - we'll get this from infra outputs
  token    = data.terraform_remote_state.infra.outputs.k8s_token
  insecure = true
  config_path = "/dev/null"
}
