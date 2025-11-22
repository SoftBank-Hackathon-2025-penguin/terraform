output "topic_arn" {
  description = "SNS 토픽 ARN"
  value       = aws_sns_topic.main.arn
}

output "topic_name" {
  description = "SNS 토픽 이름"
  value       = aws_sns_topic.main.name
}

output "topic_id" {
  description = "SNS 토픽 ID"
  value       = aws_sns_topic.main.id
}