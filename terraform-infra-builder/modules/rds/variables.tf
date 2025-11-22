variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "engine" {
  description = "데이터베이스 엔진 (mysql, postgres)"
  type        = string
}

variable "engine_version" {
  description = "엔진 버전"
  type        = string
}

variable "instance_class" {
  description = "인스턴스 클래스"
  type        = string
}

variable "allocated_storage" {
  description = "할당된 스토리지 (GB)"
  type        = number
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "username" {
  description = "마스터 사용자 이름"
  type        = string
}

variable "password" {
  description = "마스터 비밀번호"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Multi-AZ 배포"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "서브넷 ID 목록"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "보안 그룹 ID 목록"
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "백업 보존 기간 (일)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "백업 시간대"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "유지보수 시간대"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "skip_final_snapshot" {
  description = "최종 스냅샷 생략 여부"
  type        = bool
  default     = false
}