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
  description = "The Cognito User Pool Domain prefix"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "cognito_domain_url" {
  description = "The full URL of the Cognito User Pool Domain"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "aws_access_key" {
  description = "AWS Access Key"
  value       = var.aws_access_key
  sensitive   = true
}

output "aws_secret_key" {
  description = "AWS Secret Key"
  value       = var.aws_secret_key
  sensitive   = true
}



output "ec2_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.k3s_node.public_ip
}

output "portal_url" {
  description = "The URL to access the portal"
  value       = "http://${aws_instance.k3s_node.public_ip}"
}
output "k8s_token" {
  description = "The token for k3s"
  value       = random_password.k8s_token.result
  sensitive   = true
}

output "aws_region" {
  value = var.aws_region
}

output "aws_access_key_value" {
  value     = var.aws_access_key
  sensitive = true
}

output "aws_secret_key_value" {
  value     = var.aws_secret_key
  sensitive = true
}


