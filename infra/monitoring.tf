# CloudWatch Log Group for K3s Node
resource "aws_cloudwatch_log_group" "k3s_logs" {
  name              = "/aws/ec2/${var.project_name}/k3s"
  retention_in_days = 7
}

# Unified CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-unified-monitor"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: EC2 CPU & Memory
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.k3s_node.id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
        }
      },
      # Widget 2: ALB Requests & Errors
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Traffic & Errors"
        }
      },
      # Widget 3: Recent Application Logs (Log Insights)
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.k3s_logs.name}' | fields @timestamp, @logStream, @message | sort @timestamp desc | limit 30"
          region  = var.aws_region
          title   = "K3s Cluster Logs (App + System)"
          view    = "table"
        }
      },
      # Widget 4: Reporter Lambda Activity
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.reporter.function_name],
            [".", "Errors", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Reporter Lambda Activity"
        }
      }
    ]
  })
}
