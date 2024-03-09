output "api_gateway_id" {
  value = aws_apigatewayv2_api.crud_api.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.crud_table.name
}

output "lambda_function_arn" {
  value = aws_lambda_function.crud_function.arn
}

output "api_gateway_endpoint_url" {
  value = aws_apigatewayv2_api.crud_api.api_endpoint
}