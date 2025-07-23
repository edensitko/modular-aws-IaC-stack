output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.asg_alb.alb_dns_name
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.asg_alb.asg_name
}

output "lambda_function_names" {
  description = "The names of the Lambda functions"
  value       = module.lambda.lambda_function_names
}

output "lambda_function_arns" {
  description = "The ARNs of the Lambda functions"
  value       = module.lambda.lambda_function_arns
}

output "api_gateway_urls" {
  description = "The URLs of the API Gateway endpoints"
  value       = module.lambda.api_gateway_urls
}
