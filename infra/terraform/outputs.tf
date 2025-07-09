output "lambda_iam_role_arn" {
  description = "The ARN of the IAM role created for the Lambda function."
  value       = aws_iam_role.lambda_exec_role.arn
}

output "lambda_iam_role_name" {
  description = "The Name of the IAM role created for the Lambda function."
  value       = aws_iam_role.lambda_exec_role.name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository created for Lambda images."
  value       = aws_ecr_repository.lambda_repo.repository_url
}

output "ecr_repository_name" {
  description = "The name of the ECR repository created for Lambda images."
  value       = aws_ecr_repository.lambda_repo.name
}

output "s3_lambda_artifacts_bucket_name" {
  description = "The name of the S3 bucket for Lambda artifacts."
  value       = aws_s3_bucket.lambda_artifacts.bucket # Using .bucket gives the name
}

output "s3_lambda_artifacts_bucket_arn" {
  description = "The ARN of the S3 bucket for Lambda artifacts."
  value       = aws_s3_bucket.lambda_artifacts.arn
}

output "s3_lambda_artifacts_bucket_id" {
  description = "The ID (name) of the S3 bucket for Lambda artifacts."
  value       = aws_s3_bucket.lambda_artifacts.id # .id also gives the name, same as .bucket
}

# VPC Outputs
output "lambda_vpc_id" {
  description = "ID of the Lambda VPC."
  value       = aws_vpc.lambda_vpc.id
}

output "lambda_public_subnet_ids" {
  description = "List of public subnet IDs for the Lambda function."
  value       = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "lambda_security_group_id" {
  description = "ID of the Lambda security group."
  value       = aws_security_group.lambda_sg.id
}

# SQS Outputs
output "sqs_event_queue_arn" {
  description = "ARN of the SQS queue for Lambda events."
  value       = aws_sqs_queue.lambda_event_source_queue.arn
}

output "sqs_event_queue_url" {
  description = "URL of the SQS queue for Lambda events."
  value       = aws_sqs_queue.lambda_event_source_queue.id # .id is the URL for SQS
}

output "sqs_event_queue_name" {
  description = "Name of the SQS queue for Lambda events."
  value       = aws_sqs_queue.lambda_event_source_queue.name
}

# Lambda Function Outputs
output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "lambda_function_qualified_arn" {
  description = "The qualified ARN of the Lambda function (includes version)."
  value       = aws_lambda_function.this.qualified_arn
}

output "lambda_function_invoke_arn" {
  description = "The invoke ARN of the Lambda function (used for API Gateway, Step Functions etc.)."
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_function_version" {
  description = "The version of the Lambda function created by Terraform (initial version)."
  value       = aws_lambda_function.this.version
}

output "lambda_live_alias_name" {
  description = "The name of the 'live' alias for the Lambda function."
  value       = aws_lambda_alias.live.name
}

output "lambda_live_alias_arn" {
  description = "The ARN of the 'live' alias for the Lambda function."
  value       = aws_lambda_alias.live.arn
}

output "lambda_live_alias_invoke_arn" {
  description = "The invoke ARN of the 'live' alias (recommended for API Gateway)."
  value       = aws_lambda_alias.live.invoke_arn
}

# Code Signing Outputs
output "lambda_code_signing_config_arn" {
  description = "ARN of the Lambda code signing configuration."
  value       = aws_lambda_code_signing_config.lambda_csc.arn
}

output "signer_signing_profile_arn" {
  description = "ARN of the AWS Signer signing profile."
  value       = aws_signer_signing_profile.lambda_profile.arn
}

output "signer_signing_profile_version_arn" {
  description = "ARN of the AWS Signer signing profile version."
  value       = aws_signer_signing_profile.lambda_profile.version_arn # Note: This is the latest version ARN of the profile itself
}

# Event Source Mapping Outputs
output "lambda_sqs_event_source_mapping_uuid" {
  description = "UUID of the SQS event source mapping for the Lambda function."
  value       = aws_lambda_event_source_mapping.sqs_mapping.uuid
}