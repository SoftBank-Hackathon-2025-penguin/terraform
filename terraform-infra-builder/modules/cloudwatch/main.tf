# modules/cloudwatch/main.tf

# CloudWatch 대시보드
resource "aws_cloudwatch_dashboard" "main" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = concat(
      # EC2 위젯
      length(var.ec2_instance_ids) > 0 ? [{
        type = "metric"
        properties = {
          metrics = [
            for instance_id in var.ec2_instance_ids : [
              "AWS/EC2", "CPUUtilization", "InstanceId", instance_id
            ]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EC2 CPU Utilization"
        }
      }] : [],
      # RDS 위젯
      length(var.rds_instance_ids) > 0 ? [{
        type = "metric"
        properties = {
          metrics = [
            for instance_id in var.rds_instance_ids : [
              "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", instance_id
            ]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "RDS CPU Utilization"
        }
      }] : []
    )
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-dashboard"
  }
}

# EC2 CPU 알람
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  count = length(var.ec2_instance_ids)

  alarm_name          = "${var.project_name}-${var.environment}-ec2-cpu-${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "EC2 CPU utilization exceeds ${var.cpu_threshold}%"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    InstanceId = var.ec2_instance_ids[count.index]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-cpu-alarm"
  }
}

# RDS CPU 알람
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = length(var.rds_instance_ids)

  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "RDS CPU utilization exceeds ${var.cpu_threshold}%"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-cpu-alarm"
  }
}

# 현재 리전 조회
data "aws_region" "current" {}