variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}
