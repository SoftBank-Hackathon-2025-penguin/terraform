output "bucket_id" {
  description = "S3 버킷 ID"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3 버킷 ARN"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "S3 버킷 도메인 이름"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "S3 버킷 리전별 도메인 이름"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}