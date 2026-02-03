variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "terraform-aws-lab"
}

variable "google_client_id" {
  description = "The Google Client ID for Cognito Federation"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "The Google Client Secret for Cognito Federation"
  type        = string
  sensitive   = true
}

variable "callback_urls" {
  description = "The callback URLs for the Cognito User Pool Client"
  type        = list(string)
  default     = ["http://localhost:3000/oauth_callback"]
}

variable "logout_urls" {
  description = "The logout URLs for the Cognito User Pool Client"
  type        = list(string)
  default     = ["http://localhost:3000/"]
}

variable "cognito_domain" {
  description = "The static domain prefix for Cognito"
  type        = string
  default     = "tf-course-lab-rateacharacter-users"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}
