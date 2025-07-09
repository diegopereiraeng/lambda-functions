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

# Variables for vpc.tf
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_az1_cidr_block" {
  description = "CIDR block for the public subnet in AZ1."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_az2_cidr_block" {
  description = "CIDR block for the public subnet in AZ2."
  type        = string
  default     = "10.0.2.0/24"
}

# Variables for sqs.tf
variable "sqs_queue_name" {
  description = "Name for the SQS queue."
  type        = string
  default     = "" # If empty, a name will be generated
}

variable "sqs_message_retention_seconds" {
  description = "The visibility timeout for the queue. An integer from 0 to 43200 (12 hours)."
  type        = number
  default     = 300 # 5 minutes
}

# Variables for signer.tf
variable "signer_profile_name_infra" {
  description = "Name for the AWS Signer signing profile created by infrastructure Terraform."
  type        = string
  default     = ""
}
