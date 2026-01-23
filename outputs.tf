output "sqs_queue_url" {
  description = "The URL of the SQS queue"
  value       = aws_sqs_queue.event_bus.id
}

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.users.id
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.client.id
}

output "dynamodb_users_table_name" {
  description = "The name of the Users DynamoDB table"
  value       = aws_dynamodb_table.users.name
}

output "dynamodb_sessions_table_name" {
  description = "The name of the Sessions DynamoDB table"
  value       = aws_dynamodb_table.sessions.name
}

output "cognito_domain" {
  description = "The Cognito User Pool Domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

