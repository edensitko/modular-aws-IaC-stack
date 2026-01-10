output "lambda_function_arns" {
  description = "The ARNs of the Lambda functions"
  value = {
    for k, v in aws_lambda_function.functions : k => v.arn
  }
}

output "lambda_function_names" {
  description = "The names of the Lambda functions"
  value = {
    for k, v in aws_lambda_function.functions : k => v.function_name
  }
}

output "lambda_function_invoke_arns" {
  description = "The invoke ARNs of the Lambda functions"
  value = {
    for k, v in aws_lambda_function.functions : k => v.invoke_arn
  }
}

output "lambda_role_arn" {
  description = "The ARN of the IAM role used by Lambda functions"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "The name of the IAM role used by Lambda functions"
  value       = aws_iam_role.lambda_role.name
}

output "api_gateway_urls" {
  description = "The URLs of the API Gateway endpoints"
  value = {
    for k, v in aws_apigatewayv2_api.lambda_api : k => "${v.api_endpoint}"
  }
}
