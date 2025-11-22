variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "key_name" {
  description = "SSH 키 페어 이름"
  type        = string
  default     = ""
}

variable "volume_size" {
  description = "루트 볼륨 크기 (GB)"
  type        = number
  default     = 20
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "서브넷 ID"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "보안 그룹 ID 목록"
  type        = list(string)
  default     = []
}

variable "allocate_eip" {
  description = "Elastic IP 할당 여부"
  type        = bool
  default     = false
}