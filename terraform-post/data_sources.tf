# Reads the Lambda Function ARN written by Harness to SSM
data "aws_ssm_parameter" "retrieved_lambda_function_arn" {
  name = "${local.ssm_path_prefix}/function_arn"
}

# Reads the Lambda "live" Alias ARN written by Harness to SSM
data "aws_ssm_parameter" "retrieved_live_alias_arn" {
  name = "${local.ssm_path_prefix}/live_alias_arn"
}

# Optional: Read the function name itself if needed and if Harness writes it.
# This might be useful if the function name in SSM is slightly different from the constructed local.harness_deployed_function_base_name
# data "aws_ssm_parameter" "retrieved_function_name" {
#   name = "${local.ssm_path_prefix}/function_name"
# }
