variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "function_name" {
  description = "Lambda 함수 이름"
  type        = string
}

variable "runtime" {
  description = "런타임 (python3.11, nodejs18.x 등)"
  type        = string
}

variable "handler" {
  description = "핸들러 함수"
  type        = string
}

variable "memory_size" {
  description = "메모리 크기 (MB)"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "타임아웃 (초)"
  type        = number
  default     = 30
}

variable "source_file" {
  description = "소스 파일 경로"
  type        = string
}

variable "vpc_config" {
  description = "VPC 설정"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "environment_variables" {
  description = "환경 변수"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch 로그 보존 기간 (일)"
  type        = number
  default     = 7
}