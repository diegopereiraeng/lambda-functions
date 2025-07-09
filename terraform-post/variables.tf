variable "aws_region" {
  description = "AWS region for the deployment."
  type        = string
  default     = "us-east-1" # Should match your Phase 1 and Harness deployment region
}

variable "application_name" {
  description = "Base name of the application/service (e.g., 'street-demo'). Used to construct SSM paths."
  type        = string
  default     = "streetdemo" # Example
}

variable "environment_name" {
  description = "Environment name (e.g., 'dev', 'staging', 'prod'). Used to construct SSM paths."
  type        = string
  default     = "dev" # Example
}

variable "sqs_event_queue_arn_from_phase1" {
  description = "ARN of the SQS queue created in Phase 1 Terraform. This will be used by the Event Source Mapping."
  type        = string
  # This value would typically be an output from your 'infra/terraform' apply.
  # Example: "arn:aws:sqs:us-east-1:123456789012:my-lambda-queue-dev"
}

variable "signer_profile_arn_from_phase1" {
  description = "ARN of the AWS Signer Signing Profile created in Phase 1 Terraform. This will be used for the Lambda Code Signing Configuration."
  type        = string
  # This value would typically be an output from your 'infra/terraform' apply.
  # Example: "arn:aws:signer:us-east-1:123456789012:/signing-profiles/my-lambda-signing-profile-dev"
}

variable "lambda_provisioned_concurrency_count" {
  description = "Number of provisioned concurrent executions for the Lambda's 'live' alias."
  type        = number
  default     = 1 # Default to 1, can be overridden
}

variable "lambda_esm_batch_size_for_sqs" {
  description = "Batch size for the SQS Event Source Mapping."
  type        = number
  default     = 10
}

variable "lambda_code_signing_policy_on_deployment" {
  description = "Policy for untrusted artifacts on deployment for Lambda Code Signing ('Warn' or 'Enforce')."
  type        = string
  default     = "Warn"
  validation {
    condition     = contains(["Warn", "Enforce"], var.lambda_code_signing_policy_on_deployment)
    error_message = "Lambda code signing policy must be either 'Warn' or 'Enforce'."
  }
}

variable "api_gateway_stage_name" {
  description = "Stage name for the API Gateway deployment (e.g., dev, v1)."
  type        = string
  default     = "dev" # Can align with environment_name or be different
}

variable "tags" {
  description = "A map of tags to assign to created resources in this post-deployment phase."
  type        = map(string)
  default     = {}
}
