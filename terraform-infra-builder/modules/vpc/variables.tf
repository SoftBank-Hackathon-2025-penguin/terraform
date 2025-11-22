variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "DNS 호스트네임 활성화"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "DNS 지원 활성화"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "가용 영역 목록"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 목록"
  type        = list(string)
}