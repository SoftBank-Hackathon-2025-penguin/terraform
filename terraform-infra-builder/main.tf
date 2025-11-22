# VPC 모듈 (조건부 생성)
module "vpc" {
  source = "./modules/vpc"
  count  = var.enable_vpc ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  
  cidr_block           = var.vpc_config.cidr_block
  enable_dns_hostnames = var.vpc_config.enable_dns_hostnames
  enable_dns_support   = var.vpc_config.enable_dns_support
  availability_zones   = var.vpc_config.availability_zones
  public_subnet_cidrs  = var.vpc_config.public_subnet_cidrs
  private_subnet_cidrs = var.vpc_config.private_subnet_cidrs
}

# EC2 모듈 (조건부 생성)
module "ec2" {
  source = "./modules/ec2"
  count  = var.enable_ec2 ? 1 : 0

  project_name  = var.project_name
  environment   = var.environment
  
  instance_type = var.ec2_config.instance_type
  ami_id        = var.ec2_config.ami_id
  key_name      = var.ec2_config.key_name
  volume_size   = var.ec2_config.volume_size
  
  # VPC가 활성화된 경우 VPC ID와 서브넷 참조
  vpc_id            = var.enable_vpc ? module.vpc[0].vpc_id : null
  subnet_id         = var.enable_vpc ? module.vpc[0].public_subnet_ids[0] : null
  vpc_security_group_ids = var.enable_vpc ? [module.vpc[0].default_security_group_id] : []
}

# RDS 모듈 (조건부 생성)
module "rds" {
  source = "./modules/rds"
  count  = var.enable_rds ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  
  engine              = var.rds_config.engine
  engine_version      = var.rds_config.engine_version
  instance_class      = var.rds_config.instance_class
  allocated_storage   = var.rds_config.allocated_storage
  db_name             = var.rds_config.db_name
  username            = var.rds_config.username
  password            = var.rds_config.password
  multi_az            = var.rds_config.multi_az
  skip_final_snapshot = var.rds_config.skip_final_snapshot
  
  # VPC가 활성화된 경우 서브넷 그룹 생성
  vpc_id              = var.enable_vpc ? module.vpc[0].vpc_id : null
  subnet_ids          = var.enable_vpc ? module.vpc[0].private_subnet_ids : []
  vpc_security_group_ids = var.enable_vpc ? [module.vpc[0].default_security_group_id] : []
}

# S3 모듈 (조건부 생성)
module "s3" {
  source = "./modules/s3"
  count  = var.enable_s3 ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  
  bucket_name       = var.s3_config.bucket_name
  enable_versioning = var.s3_config.enable_versioning
  enable_encryption = var.s3_config.enable_encryption
  lifecycle_rules   = var.s3_config.lifecycle_rules
}

# Lambda 모듈 (조건부 생성)
module "lambda" {
  source = "./modules/lambda"
  count  = var.enable_lambda ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  
  function_name = var.lambda_config.function_name
  runtime       = var.lambda_config.runtime
  handler       = var.lambda_config.handler
  memory_size   = var.lambda_config.memory_size
  timeout       = var.lambda_config.timeout
  source_file   = var.lambda_config.source_file
  
  # VPC가 활성화된 경우 Lambda를 VPC 내에 배포
  vpc_config = var.enable_vpc ? {
    subnet_ids         = module.vpc[0].private_subnet_ids
    security_group_ids = [module.vpc[0].default_security_group_id]
  } : null
}

# CloudWatch 모듈 (조건부 생성)
module "cloudwatch" {
  source = "./modules/cloudwatch"
  count  = var.enable_cloudwatch ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  
  create_dashboard  = var.cloudwatch_config.create_dashboard
  alarm_email      = var.cloudwatch_config.alarm_email
  cpu_threshold    = var.cloudwatch_config.cpu_threshold
  memory_threshold = var.cloudwatch_config.memory_threshold
  
  # EC2가 활성화된 경우 인스턴스 ID 전달
  ec2_instance_ids = var.enable_ec2 ? [module.ec2[0].instance_id] : []
  
  # RDS가 활성화된 경우 DB 식별자 전달
  rds_instance_ids = var.enable_rds ? [module.rds[0].db_instance_id] : []
  
  # SNS 토픽 ARN (SNS가 활성화된 경우)
  sns_topic_arn = var.enable_sns ? module.sns[0].topic_arn : null
}

# SNS 모듈 (조건부 생성)
module "sns" {
  source = "./modules/sns"
  count  = var.enable_sns ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  
  topic_name      = var.sns_config.topic_name
  display_name    = var.sns_config.display_name
  email_endpoints = var.sns_config.email_endpoints
  sms_endpoints   = var.sns_config.sms_endpoints
}