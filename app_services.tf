resource "aws_sqs_queue" "event_bus" {
  name                      = "${var.project_name}-event-bus"
  message_retention_seconds = 86400 # 1 day
  receive_wait_time_seconds = 10    # Long polling

  tags = {
    Project = var.project_name
  }
}

resource "aws_cognito_user_pool" "users" {
  name = "${var.project_name}-user-pool"

  # Allow users to sign in using their email address
  username_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.users.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

resource "aws_dynamodb_table" "users" {
  name           = "${var.project_name}-users"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_dynamodb_table" "sessions" {
  name           = "${var.project_name}-sessions"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "sessionId"

  attribute {
    name = "sessionId"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "tf-course-lab-${random_id.cognito_domain.hex}"
  user_pool_id = aws_cognito_user_pool.users.id
}

resource "random_id" "cognito_domain" {
  byte_length = 4
}

