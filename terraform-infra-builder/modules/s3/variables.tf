variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "bucket_name" {
  description = "S3 버킷 이름"
  type        = string
}

variable "enable_versioning" {
  description = "버전 관리 활성화"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "암호화 활성화"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "라이프사이클 규칙 활성화"
  type        = bool
  default     = false
}

variable "enable_cors" {
  description = "CORS 활성화"
  type        = bool
  default     = false
}