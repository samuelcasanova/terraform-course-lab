# Generate terraform.env file for backend application
resource "local_file" "backend_env" {
  filename = "${path.module}/../apps/terraform.env"
  
  content = <<-EOT
# This file is auto-generated from Terraform
# DO NOT EDIT MANUALLY - Changes will be overwritten on next terraform apply

AWS_ACCESS_KEY="${var.aws_access_key}"
AWS_SECRET_KEY="${var.aws_secret_key}"
COGNITO_DOMAIN="${aws_cognito_user_pool_domain.main.domain}"
COGNITO_DOMAIN_URL="https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
COGNITO_USER_POOL_CLIENT_ID="${aws_cognito_user_pool_client.client.id}"
COGNITO_USER_POOL_ID="${aws_cognito_user_pool.users.id}"
DYNAMODB_SESSIONS_TABLE_NAME="${aws_dynamodb_table.sessions.name}"
DYNAMODB_USERS_TABLE_NAME="${aws_dynamodb_table.users.name}"
SQS_QUEUE_URL="${aws_sqs_queue.event_bus.id}"
  ALB_DNS_NAME="${aws_lb.main.dns_name}"
  EC2_PUBLIC_IP="${aws_instance.k3s_node.public_ip}"
  OAUTH_REDIRECT_URI="https://${aws_lb.main.dns_name}/oauth_callback"
  OAUTH_SCOPE="openid profile email"
  OAUTH_STATE="google"
  OAUTH_LOGIN_SERVICE_URL="https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize"
  OAUTH_TOKEN_SERVICE_URL="https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token"
EOT

  file_permission = "0644"
}
