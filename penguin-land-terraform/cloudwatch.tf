# CloudWatch Log Group for EC2
resource "aws_cloudwatch_log_group" "ec2_app" {
  name              = "/aws/ec2/penguin-land/${var.session_id}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.session_id}-ec2-logs"
  }
}

# ===== CPU Utilization Alarms =====

# CPU Warning Alarm (50% 이상)
resource "aws_cloudwatch_metric_alarm" "cpu_warning" {
  alarm_name          = "${var.project_name}-${var.session_id}-cpu-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_warning_threshold
  alarm_description   = "CPU 사용률이 ${var.cpu_warning_threshold}%를 초과했습니다"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app_server.id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Name     = "${var.project_name}-${var.session_id}-cpu-warning"
    Severity = "warning"
  }
}

# CPU Critical Alarm (70% 이상)
resource "aws_cloudwatch_metric_alarm" "cpu_critical" {
  alarm_name          = "${var.project_name}-${var.session_id}-cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_critical_threshold
  alarm_description   = "CPU 사용률이 ${var.cpu_critical_threshold}%를 초과했습니다 (위험)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app_server.id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Name     = "${var.project_name}-${var.session_id}-cpu-critical"
    Severity = "critical"
  }
}

# ===== Memory Utilization Alarm (Custom Metric) =====

resource "aws_cloudwatch_metric_alarm" "memory_warning" {
  alarm_name          = "${var.project_name}-${var.session_id}-memory-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MEM_USED"
  namespace           = "PenguinLand/${var.session_id}"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "메모리 사용률이 80%를 초과했습니다"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Name     = "${var.project_name}-${var.session_id}-memory-warning"
    Severity = "warning"
  }
}

# ===== Status Check Alarms =====

# EC2 Instance Status Check Failed
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "${var.project_name}-${var.session_id}-instance-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "EC2 인스턴스 상태 체크에 실패했습니다"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app_server.id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Name     = "${var.project_name}-${var.session_id}-instance-status-check"
    Severity = "critical"
  }
}

# EC2 System Status Check Failed
resource "aws_cloudwatch_metric_alarm" "system_status_check" {
  alarm_name          = "${var.project_name}-${var.session_id}-system-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "EC2 시스템 상태 체크에 실패했습니다"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app_server.id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Name     = "${var.project_name}-${var.session_id}-system-status-check"
    Severity = "critical"
  }
}

# ===== Disk Utilization Alarm =====

resource "aws_cloudwatch_metric_alarm" "disk_warning" {
  alarm_name          = "${var.project_name}-${var.session_id}-disk-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DISK_USED"
  namespace           = "PenguinLand/${var.session_id}"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "디스크 사용률이 80%를 초과했습니다"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Name     = "${var.project_name}-${var.session_id}-disk-warning"
    Severity = "warning"
  }
}

# ===== Lambda Error Rate Alarm =====

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.session_id}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda 함수에서 5개 이상의 에러가 발생했습니다"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.alarm_processor.function_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Name     = "${var.project_name}-${var.session_id}-lambda-errors"
    Severity = "warning"
  }
}

# ===== Lambda Throttle Alarm =====

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-${var.session_id}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda 함수가 스로틀링되고 있습니다"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.alarm_processor.function_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Name     = "${var.project_name}-${var.session_id}-lambda-throttles"
    Severity = "critical"
  }
}

# ===== Composite Alarm (종합 알람) =====

resource "aws_cloudwatch_composite_alarm" "system_health" {
  alarm_name          = "${var.project_name}-${var.session_id}-system-health"
  alarm_description   = "시스템 전체 상태를 나타내는 종합 알람"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.cpu_critical.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.instance_status_check.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.system_status_check.alarm_name})"

  tags = {
    Name     = "${var.project_name}-${var.session_id}-system-health"
    Severity = "critical"
  }
}

# ===== CloudWatch Dashboard =====

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.session_id}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "CPU 사용률" }]
          ]
          period = 300
          region = var.aws_region
          title  = "EC2 CPU 사용률"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["PenguinLand/${var.session_id}", "MEM_USED", { stat = "Average", label = "메모리 사용률" }]
          ]
          period = 300
          region = var.aws_region
          title  = "메모리 사용률"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["PenguinLand/${var.session_id}", "RiskScore", { stat = "Average", label = "위험 점수" }]
          ]
          period = 300
          region = var.aws_region
          title  = "위험 점수 (Penguin Status)"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Lambda 호출" }],
            [".", "Errors", { stat = "Sum", label = "Lambda 에러" }]
          ]
          period = 300
          region = var.aws_region
          title  = "Lambda 함수 메트릭"
        }
      }
    ]
  })
}
