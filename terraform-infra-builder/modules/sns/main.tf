# SNS 토픽
resource "aws_sns_topic" "main" {
  name         = var.topic_name
  display_name = var.display_name

  tags = {
    Name = "${var.project_name}-${var.environment}-sns-topic"
  }
}

# 이메일 구독
resource "aws_sns_topic_subscription" "email" {
  count = length(var.email_endpoints)

  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = var.email_endpoints[count.index]
}

# SMS 구독
resource "aws_sns_topic_subscription" "sms" {
  count = length(var.sms_endpoints)

  topic_arn = aws_sns_topic.main.arn
  protocol  = "sms"
  endpoint  = var.sms_endpoints[count.index]
}

# SNS 토픽 정책
resource "aws_sns_topic_policy" "main" {
  arn = aws_sns_topic.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.main.arn
      }
    ]
  })
}