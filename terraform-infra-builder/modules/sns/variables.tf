variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "topic_name" {
  description = "SNS 토픽 이름"
  type        = string
}

variable "display_name" {
  description = "SNS 토픽 표시 이름"
  type        = string
  default     = ""
}

variable "email_endpoints" {
  description = "이메일 엔드포인트 목록"
  type        = list(string)
  default     = []
}

variable "sms_endpoints" {
  description = "SMS 엔드포인트 목록"
  type        = list(string)
  default     = []
}