# Code Signing Configuration for the Lambda deployed by Harness
resource "aws_lambda_code_signing_config" "deployed_lambda_csc" {
  allowed_publishers {
    signing_profile_version_arns = [var.signer_profile_arn_from_phase1] # ARN from initial TF phase
  }
  policies {
    untrusted_artifact_on_deployment = var.lambda_code_signing_policy_on_deployment
  }
  description = "Code Signing Config for ${local.harness_deployed_function_base_name}"

  tags = local.common_tags
}

# Apply the Code Signing Configuration to the Lambda function
resource "aws_lambda_function_code_signing_config" "apply_csc_to_deployed_lambda" {
  function_arn            = data.aws_ssm_parameter.retrieved_lambda_function_arn.value # ARN from SSM
  code_signing_config_arn = aws_lambda_code_signing_config.deployed_lambda_csc.arn

  # This resource can sometimes cause issues if the Lambda function's update races with CSC creation.
  # No explicit depends_on needed as function_arn is from a data source, which implies the SSM param must exist.
}

# Provisioned Concurrency for the "live" alias of the Lambda deployed by Harness
resource "aws_lambda_provisioned_concurrency_config" "deployed_lambda_live_alias_pc" {
  # The function_name for provisioned concurrency should be the base function name, not the alias ARN.
  # We can extract this from the alias ARN or function ARN if Harness writes the full function name.
  # Assuming local.harness_deployed_function_base_name correctly matches the actual function name.
  function_name                     = local.harness_deployed_function_base_name
  qualifier                         = "live" # The alias name Harness is expected to create/manage
  provisioned_concurrent_executions = var.lambda_provisioned_concurrency_count

  tags = local.common_tags

  # This implicitly depends on the alias "live" existing on the function.
  # Harness is responsible for creating this alias.
}

# Event Source Mapping for the "live" alias of the Lambda deployed by Harness
resource "aws_lambda_event_source_mapping" "deployed_lambda_sqs_esm" {
  event_source_arn = var.sqs_event_queue_arn_from_phase1 # ARN from initial TF phase
  function_name    = data.aws_ssm_parameter.retrieved_live_alias_arn.value # Map to the "live" alias ARN from SSM
  batch_size       = var.lambda_esm_batch_size_for_sqs
  enabled          = true

  # Add filter_criteria here if needed:
  # filter_criteria {
  #   filter {
  #     pattern     = jsonencode({ "body" : { "type" : ["important"] }})
  #   }
  # }

  # This implicitly depends on the SQS queue and the Lambda alias existing.
}
