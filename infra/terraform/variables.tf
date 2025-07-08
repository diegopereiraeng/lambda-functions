variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "A name for the project, used for tagging and naming resources."
  type        = string
  default     = "streetdemo"
}

variable "environment_name" {
  description = "The environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "lambda_iam_role_name" {
  description = "Custom name for the Lambda IAM role. If not set, a name will be generated."
  type        = string
  default     = ""
}

variable "ecr_repository_name" {
  description = "Custom name for the ECR repository. If not set, a name will be generated."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to created resources."
  type        = map(string)
  default     = {}
}
