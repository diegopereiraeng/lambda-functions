resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "${local.harness_deployed_function_base_name}-api"
  description = "API Gateway for Lambda function ${local.harness_deployed_function_base_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "{proxy+}" # Greedy proxy
}

resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE" # Change as needed, e.g., "AWS_IAM", "CUSTOM", "COGNITO_USER_POOLS"
}

resource "aws_api_gateway_integration" "lambda_proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  integration_http_method = "POST" # For AWS_PROXY type
  type                    = "AWS_PROXY"

  # Use the "live" alias ARN retrieved from SSM
  uri = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${data.aws_ssm_parameter.retrieved_live_alias_arn.value}/invocations"

  # This depends on the SSM parameter being available, which implies Harness has run.
}

# Catch-all method for the root resource, if you want to handle requests to "/"
resource "aws_api_gateway_method" "root_any" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_rest_api.lambda_api.root_resource_id
  http_method             = aws_api_gateway_method.root_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${data.aws_ssm_parameter.retrieved_live_alias_arn.value}/invocations"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_proxy_integration,
    aws_api_gateway_integration.root_lambda_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = var.api_gateway_stage_name # e.g., "dev", "prod", "v1"

  # Terraform can create a new deployment each time, or you can manage this more explicitly.
  # Setting triggers will cause a new deployment on changes to specified resources.
  # Here, any change to the API definition (integrations, methods, etc.) will trigger a new deployment.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.lambda_api.body,
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_integration.lambda_proxy_integration.id,
      aws_api_gateway_method.root_any.id,
      aws_api_gateway_integration.root_lambda_integration.id
      # Add other resources that define the API structure
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda permission for API Gateway to invoke the "live" alias
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_ssm_parameter.retrieved_live_alias_arn.value # Permission the alias
  principal     = "apigateway.amazonaws.com"

  # Restrict to the specific API Gateway ARN for better security
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.lambda_api.id}/*/*"
}
