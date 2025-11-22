variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "create_dashboard" {
  description = "대시보드 생성 여부"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "알람 이메일 주소"
  type        = string
  default     = ""
}

variable "cpu_threshold" {
  description = "CPU 임계값 (%)"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "메모리 임계값 (%)"
  type        = number
  default     = 80
}

variable "ec2_instance_ids" {
  description = "모니터링할 EC2 인스턴스 ID 목록"
  type        = list(string)
  default     = []
}

variable "rds_instance_ids" {
  description = "모니터링할 RDS 인스턴스 ID 목록"
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  description = "알람 전송용 SNS 토픽 ARN"
  type        = string
  default     = null
}