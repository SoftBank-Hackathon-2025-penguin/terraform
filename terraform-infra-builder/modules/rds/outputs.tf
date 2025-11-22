output "db_instance_id" {
  description = "DB 인스턴스 ID"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "DB 엔드포인트"
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "DB 포트"
  value       = aws_db_instance.main.port
}

output "db_arn" {
  description = "DB ARN"
  value       = aws_db_instance.main.arn
}