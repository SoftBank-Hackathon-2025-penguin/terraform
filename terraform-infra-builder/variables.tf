# 공통 변수
variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}

# 모듈 활성화 플래그 (프론트엔드에서 조작)
variable "enable_vpc" {
  description = "VPC 모듈 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_ec2" {
  description = "EC2 모듈 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_rds" {
  description = "RDS 모듈 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_s3" {
  description = "S3 모듈 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Lambda 모듈 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_cloudwatch" {
  description = "CloudWatch 모듈 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_sns" {
  description = "SNS 모듈 활성화 여부"
  type        = bool
  default     = false
}

# VPC 설정
variable "vpc_config" {
  description = "VPC 설정"
  type = object({
    cidr_block           = string
    enable_dns_hostnames = bool
    enable_dns_support   = bool
    availability_zones   = list(string)
    public_subnet_cidrs  = list(string)
    private_subnet_cidrs = list(string)
  })
  default = {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
    public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  }
}

# EC2 설정
variable "ec2_config" {
  description = "EC2 인스턴스 설정"
  type = object({
    instance_type = string
    ami_id        = string
    key_name      = string
    volume_size   = number
  })
  default = {
    instance_type = "t3.micro"
    ami_id        = "" # 프론트엔드에서 설정
    key_name      = ""
    volume_size   = 20
  }
}

# RDS 설정
variable "rds_config" {
  description = "RDS 데이터베이스 설정"
  type = object({
    engine               = string
    engine_version       = string
    instance_class       = string
    allocated_storage    = number
    db_name              = string
    username             = string
    password             = string
    multi_az             = bool
    skip_final_snapshot  = bool
  })
  default = {
    engine               = "mysql"
    engine_version       = "8.0"
    instance_class       = "db.t3.micro"
    allocated_storage    = 20
    db_name              = "mydb"
    username             = "admin"
    password             = ""
    multi_az             = false
    skip_final_snapshot  = true
  }
  sensitive = true
}

# S3 설정
variable "s3_config" {
  description = "S3 버킷 설정"
  type = object({
    bucket_name         = string
    enable_versioning   = bool
    enable_encryption   = bool
    lifecycle_rules     = bool
  })
  default = {
    bucket_name         = ""
    enable_versioning   = true
    enable_encryption   = true
    lifecycle_rules     = false
  }
}

# Lambda 설정
variable "lambda_config" {
  description = "Lambda 함수 설정"
  type = object({
    function_name = string
    runtime       = string
    handler       = string
    memory_size   = number
    timeout       = number
    source_file   = string
  })
  default = {
    function_name = ""
    runtime       = "python3.11"
    handler       = "lambda_function.lambda_handler"
    memory_size   = 128
    timeout       = 30
    source_file   = ""
  }
}

# CloudWatch 설정
variable "cloudwatch_config" {
  description = "CloudWatch 알람 설정"
  type = object({
    create_dashboard     = bool
    alarm_email         = string
    cpu_threshold       = number
    memory_threshold    = number
  })
  default = {
    create_dashboard     = true
    alarm_email         = ""
    cpu_threshold       = 80
    memory_threshold    = 80
  }
}

# SNS 설정
variable "sns_config" {
  description = "SNS 토픽 설정"
  type = object({
    topic_name          = string
    display_name        = string
    email_endpoints     = list(string)
    sms_endpoints       = list(string)
  })
  default = {
    topic_name          = ""
    display_name        = ""
    email_endpoints     = []
    sms_endpoints       = []
  }
}