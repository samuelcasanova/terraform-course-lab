terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  # When k8s_enabled is false (Step 1), we use a placeholder to avoid plan errors.
  # When k8s_enabled is true (Step 2), we use the actual EC2 IP.
  host = var.k8s_enabled ? "https://${aws_instance.k3s_node.public_ip}:6443" : "https://127.0.0.1:6443"
  
  token    = random_password.k8s_token.result
  insecure = true
}

