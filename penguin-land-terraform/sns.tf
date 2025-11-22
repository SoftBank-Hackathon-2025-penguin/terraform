# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  name              = "${var.project_name}-${var.session_id}-alarms"
  display_name      = "Penguin Land Alarms (${var.session_id})"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name    = "${var.project_name}-${var.session_id}-alarms"
    Purpose = "CloudWatch alarm notifications"
  }
}

# SNS Topic Subscription (이메일)
resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# SNS Topic Subscription (Lambda)
resource "aws_sns_topic_subscription" "alarms_lambda" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm_processor.arn
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alarms" {
  arn = aws_sns_topic.alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alarms.arn
      },
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alarms.arn
      }
    ]
  })
}
