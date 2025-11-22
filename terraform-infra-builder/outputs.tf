# VPC 출력
output "vpc_outputs" {
  description = "VPC 모듈 출력값"
  value = var.enable_vpc ? {
    vpc_id              = module.vpc[0].vpc_id
    public_subnet_ids   = module.vpc[0].public_subnet_ids
    private_subnet_ids  = module.vpc[0].private_subnet_ids
    nat_gateway_ids     = module.vpc[0].nat_gateway_ids
  } : null
}

# EC2 출력
output "ec2_outputs" {
  description = "EC2 모듈 출력값"
  value = var.enable_ec2 ? {
    instance_id  = module.ec2[0].instance_id
    public_ip    = module.ec2[0].public_ip
    private_ip   = module.ec2[0].private_ip
  } : null
}

# RDS 출력
output "rds_outputs" {
  description = "RDS 모듈 출력값"
  value = var.enable_rds ? {
    db_instance_id       = module.rds[0].db_instance_id
    db_endpoint          = module.rds[0].db_endpoint
    db_port              = module.rds[0].db_port
  } : null
  sensitive = true
}

# S3 출력
output "s3_outputs" {
  description = "S3 모듈 출력값"
  value = var.enable_s3 ? {
    bucket_id  = module.s3[0].bucket_id
    bucket_arn = module.s3[0].bucket_arn
  } : null
}

# Lambda 출력
output "lambda_outputs" {
  description = "Lambda 모듈 출력값"
  value = var.enable_lambda ? {
    function_name = module.lambda[0].function_name
    function_arn  = module.lambda[0].function_arn
    invoke_arn    = module.lambda[0].invoke_arn
  } : null
}

# CloudWatch 출력
output "cloudwatch_outputs" {
  description = "CloudWatch 모듈 출력값"
  value = var.enable_cloudwatch ? {
    dashboard_name = module.cloudwatch[0].dashboard_name
    alarm_arns     = module.cloudwatch[0].alarm_arns
  } : null
}

# SNS 출력
output "sns_outputs" {
  description = "SNS 모듈 출력값"
  value = var.enable_sns ? {
    topic_arn  = module.sns[0].topic_arn
    topic_name = module.sns[0].topic_name
  } : null
}