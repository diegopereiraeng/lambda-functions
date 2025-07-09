# This file defines the AWS Lambda function, an S3 object for its initial code,
# and a Lambda alias for stable endpoint access.

# This object will be the initial code package for the Lambda function.
# The actual zip file 'dummy_lambda_payload.zip' needs to be present
# in the path specified by var.dummy_payload_path during terraform apply.
resource "aws_s3_object" "dummy_lambda_zip" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  key    = "lambda_artifacts/dummy_lambda_payload_tf_initial.zip" # Path within the S3 bucket
  source = pathexpand("dummy_lambda_payload.zip") # Path to the local dummy zip file
  # etag is used for source_code_hash, so ensure it's computed from the file content
  # For local files, Terraform automatically computes the MD5 hash for etag.
}

resource "aws_lambda_function" "street_demo_lambda" {
  function_name = "${var.project_name}-street-demo-${var.environment_name}"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "app.handler" # Assuming the dummy zip has app.py with handler function
  runtime       = "python3.11"
  timeout       = 30  # seconds
  memory_size   = 256 # MB

  s3_bucket         = aws_s3_bucket.lambda_artifacts.id
  s3_key            = aws_s3_object.dummy_lambda_zip.key
  source_code_hash  = aws_s3_object.dummy_lambda_zip.etag # Ensures Lambda updates if dummy zip changes

  # Enable this if you want AWS to automatically create versions when config/code changes
  # This is generally recommended for use with aliases.
  publish = true

  environment {
    variables = {
      BANK_OFFER_ID  = "TF_DEFAULT_OFFER_INIT"
      DEMO_VERSION   = "tf-initial-v0.1"
      LOG_LEVEL      = "INFO"
      DEPLOYMENT_ENV = var.environment_name
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-street-demo-${var.environment_name}"
      Project     = var.project_name
      Environment = var.environment_name
      ManagedBy   = "Terraform"
    }
  )

  # Depending on your VPC requirements, you might need to add vpc_config
  # vpc_config {
  #   subnet_ids         = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
  #   security_group_ids = ["sg-zzzzzzzzzzzzzzzzz"]
  # }

  # Add depends_on if there are implicit dependencies not caught by Terraform
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_s3_object.dummy_lambda_zip
  ]
}

resource "aws_lambda_alias" "demo_alias" {
  name             = "live" # Or var.lambda_alias_name if you add a variable for it
  function_name    = aws_lambda_function.street_demo_lambda.function_name
  function_version = aws_lambda_function.street_demo_lambda.version # Points to the initial published version

  # Optional: Routing configuration for blue/green or canary deployments
  # routing_config {
  #   additional_version_weights = {
  #     "2" = 0.05 # 5% of traffic to version 2
  #   }
  # }
}
