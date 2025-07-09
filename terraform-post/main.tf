provider "aws" {
  region = var.aws_region
}

locals {
  # Construct the function name as deployed by Harness (assuming <application_name>-<environment_name> pattern from Harness service/env names)
  # This needs to match the function name part used by Harness when it writes to SSM.
  # If Harness writes /app/<ACTUAL_FUNCTION_NAME_FROM_HARNESS>/..., then you might need to get that actual name first.
  # For this example, we assume a predictable pattern based on app and env.
  # The SSM path written by Harness in the guide was: /app/${FUNCTION_NAME}/...
  # So, if FUNCTION_NAME from Harness is "streetdemo-dev", then deployed_lambda_base_name should be "streetdemo-dev".
  # We'll use var.application_name and var.environment_name to construct this.

  # This local variable will be the base name for the Lambda function,
  # e.g., "streetdemo-dev" if application_name is "streetdemo" and environment_name is "dev".
  # This should match the <+service.name>-<+env.name> pattern from Harness.
  harness_deployed_function_base_name = "${var.application_name}-${var.environment_name}"

  ssm_path_prefix = "/app/${local.harness_deployed_function_base_name}"

  common_tags = merge(
    var.tags, # User-provided tags
    {
      DeployedBy  = "Terraform-Post-Harness"
      Application = var.application_name
      Environment = var.environment_name
    }
  )
}

# Required to make API Gateway integration URI construction easier if region is not hardcoded
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
