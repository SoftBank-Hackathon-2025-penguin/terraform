output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "퍼블릭 IP"
  value       = aws_instance.main.public_ip
}

output "private_ip" {
  description = "프라이빗 IP"
  value       = aws_instance.main.private_ip
}

output "eip" {
  description = "Elastic IP (할당된 경우)"
  value       = var.allocate_eip ? aws_eip.main[0].public_ip : null
}