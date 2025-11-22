output "function_name" {
  description = "Lambda 함수 이름"
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "Lambda 함수 ARN"
  value       = aws_lambda_function.main.arn
}

output "invoke_arn" {
  description = "Lambda Invoke ARN"
  value       = aws_lambda_function.main.invoke_arn
}

output "role_arn" {
  description = "Lambda 실행 역할 ARN"
  value       = aws_iam_role.lambda.arn
}