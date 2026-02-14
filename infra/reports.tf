# IAM Role for Lambda
resource "aws_iam_role" "lambda_reporter_role" {
  name = "${var.project_name}-lambda-reporter-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda (DynamoDB Read, S3 Write, CloudWatch Logs)
resource "aws_iam_role_policy" "lambda_reporter_policy" {
  name = "${var.project_name}-lambda-reporter-policy"
  role = aws_iam_role.lambda_reporter_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem"
        ]
        Effect   = "Allow"
        Resource = [
          aws_dynamodb_table.users.arn,
          aws_dynamodb_table.sessions.arn
        ]
      },
      {
        Action = [
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.assets.arn}/reports/*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Archive the Lambda code
data "archive_file" "lambda_reporter_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_reporter/index.py"
  output_path = "${path.module}/lambda_reporter.zip"
}

# Lambda Function
resource "aws_lambda_function" "reporter" {
  filename         = data.archive_file.lambda_reporter_zip.output_path
  function_name    = "${var.project_name}-reporter"
  role             = aws_iam_role.lambda_reporter_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_reporter_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      USERS_TABLE    = aws_dynamodb_table.users.name
      SESSIONS_TABLE = aws_dynamodb_table.sessions.name
      ASSETS_BUCKET  = aws_s3_bucket.assets.id
    }
  }
}

# EventBridge Rule (Weekly)
resource "aws_cloudwatch_event_rule" "weekly_report" {
  name                = "${var.project_name}-weekly-report-trigger"
  description         = "Triggers the reporter lambda weekly"
  schedule_expression = "rate(7 days)"
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "reporter_target" {
  rule      = aws_cloudwatch_event_rule.weekly_report.name
  target_id = "ReporterLambda"
  arn       = aws_lambda_function.reporter.arn
}

# Permission for EventBridge to call Lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_report.arn
}
