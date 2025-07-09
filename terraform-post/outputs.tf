output "api_gateway_invoke_url" {
  description = "The invoke URL for the deployed API Gateway stage."
  value       = aws_api_gateway_deployment.api_deployment.invoke_url
}

output "api_gateway_id" {
  description = "The ID of the deployed API Gateway."
  value       = aws_api_gateway_rest_api.lambda_api.id
}

output "lambda_code_signing_config_arn_post" {
  description = "ARN of the Lambda Code Signing Configuration applied in post-deployment."
  value       = aws_lambda_code_signing_config.deployed_lambda_csc.arn
}

output "lambda_event_source_mapping_uuid_post" {
  description = "UUID of the SQS Event Source Mapping created in post-deployment."
  value       = aws_lambda_event_source_mapping.deployed_lambda_sqs_esm.uuid
}

output "retrieved_lambda_function_arn_from_ssm" {
  description = "Lambda function ARN retrieved from SSM (deployed by Harness)."
  value       = data.aws_ssm_parameter.retrieved_lambda_function_arn.value
}

output "retrieved_live_alias_arn_from_ssm" {
  description = "Lambda 'live' alias ARN retrieved from SSM (managed by Harness)."
  value       = data.aws_ssm_parameter.retrieved_live_alias_arn.value
}
