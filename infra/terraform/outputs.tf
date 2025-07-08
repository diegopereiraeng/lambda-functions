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

output "lambda_function_name" {
  description = "The name of the created AWS Lambda function."
  value       = aws_lambda_function.street_demo_lambda.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the created AWS Lambda function."
  value       = aws_lambda_function.street_demo_lambda.arn
}

output "lambda_function_qualified_arn" {
  description = "The qualified ARN of the created AWS Lambda function (includes the version)."
  value       = aws_lambda_function.street_demo_lambda.qualified_arn
}

output "lambda_function_invoke_arn" {
  description = "The invoke ARN of the created AWS Lambda function."
  value       = aws_lambda_function.street_demo_lambda.invoke_arn
}

output "lambda_alias_name" {
  description = "The name of the Lambda alias."
  value       = aws_lambda_alias.demo_alias.name
}

output "lambda_alias_arn" {
  description = "The ARN of the Lambda alias."
  value       = aws_lambda_alias.demo_alias.arn
}

output "lambda_alias_invoke_arn" {
  description = "The Invoke ARN of the Lambda alias."
  value       = aws_lambda_alias.demo_alias.invoke_arn
}
