locals {
  lambda_functions = {
    hello_world = {
      filename      = "${path.module}/functions/hello_world.py"
      function_name = "${var.name_prefix}-hello-world"
      handler       = "hello_world.lambda_handler"
      runtime       = "python3.9"
      timeout       = 30
      memory_size   = 128
      description   = "A simple hello world Lambda function"
      environment_variables = {}
      create_api_gateway = true
    },
    s3_processor = {
      filename      = "${path.module}/functions/s3_processor.py"
      function_name = "${var.name_prefix}-s3-processor"
      handler       = "s3_processor.lambda_handler"
      runtime       = "python3.9"
      timeout       = 60
      memory_size   = 256
      description   = "Lambda function for processing S3 events"
      environment_variables = {}
      create_api_gateway = false
    },
    cost_calculator = {
      filename      = "${path.module}/functions/cost_calculator.py"
      function_name = "${var.name_prefix}-cost-calculator"
      handler       = "cost_calculator.lambda_handler"
      runtime       = "python3.9"
      timeout       = 120
      memory_size   = 256
      description   = "Lambda function for calculating AWS resource costs and sending notifications"
      environment_variables = {
        DISCORD_WEBHOOK_URL = var.discord_webhook_url
        SLACK_WEBHOOK_URL = var.slack_webhook_url
        TELEGRAM_API_URL = var.telegram_api_url
      }
      create_api_gateway = true
    }
  }
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach S3 read policy for the s3_processor function
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Attach Cost Explorer read policy for the cost_calculator function
resource "aws_iam_role_policy_attachment" "lambda_ce" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCostExplorerServiceFullAccess"
}

# Attach EC2 read policy for the cost_calculator function
resource "aws_iam_role_policy_attachment" "lambda_ec2" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Attach RDS read policy for the cost_calculator function
resource "aws_iam_role_policy_attachment" "lambda_rds" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

# Attach Lambda read policy for the cost_calculator function
resource "aws_iam_role_policy_attachment" "lambda_lambda" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaReadOnlyAccess"
}

# Create Lambda functions from the local map
resource "aws_lambda_function" "functions" {
  for_each = local.lambda_functions

  function_name = each.value.function_name
  filename      = each.value.filename
  role          = aws_iam_role.lambda_role.arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size
  description   = each.value.description

  dynamic "environment" {
    for_each = length(each.value.environment_variables) > 0 ? [1] : []
    content {
      variables = each.value.environment_variables
    }
  }

  tags = var.tags
}

# Create CloudWatch Log Groups for each Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambda_functions

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Create API Gateway resources for functions that need them
resource "aws_apigatewayv2_api" "lambda_api" {
  for_each = {
    for k, v in local.lambda_functions : k => v
    if v.create_api_gateway
  }

  name          = "${each.value.function_name}-api"
  protocol_type = "HTTP"
  
  tags = var.tags
}

resource "aws_apigatewayv2_stage" "lambda_stage" {
  for_each = aws_apigatewayv2_api.lambda_api

  api_id      = each.value.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs[each.key].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_logs" {
  for_each = aws_apigatewayv2_api.lambda_api

  name              = "/aws/apigateway/${each.value.name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  for_each = aws_apigatewayv2_api.lambda_api

  api_id           = each.value.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Lambda integration"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.functions[each.key].invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  for_each = aws_apigatewayv2_api.lambda_api

  api_id    = each.value.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[each.key].id}"
}

resource "aws_lambda_permission" "api_gateway" {
  for_each = aws_apigatewayv2_api.lambda_api

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${each.value.execution_arn}/*/*"
}