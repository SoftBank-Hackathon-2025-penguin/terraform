output "dashboard_name" {
  description = "CloudWatch 대시보드 이름"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

output "alarm_arns" {
  description = "CloudWatch 알람 ARN 목록"
  value       = concat(aws_cloudwatch_metric_alarm.ec2_cpu[*].arn, aws_cloudwatch_metric_alarm.rds_cpu[*].arn)
}