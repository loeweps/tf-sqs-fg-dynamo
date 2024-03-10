
output "dynamodb_table_name" {
  value = aws_dynamodb_table.crud_table.name
}

output "lambda_function_arn" {
  value = aws_lambda_function.crud_function.arn
}
