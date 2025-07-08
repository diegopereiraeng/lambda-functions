# This main.tf file is the entrypoint for this Terraform configuration.
# It configures the AWS provider.
# For this specific setup, resource definitions are kept in separate
# files (iam.tf, ecr.tf) for better organization.

provider "aws" {
  region = var.aws_region
  # Other provider configurations can go here, e.g.:
  # default_tags {
  #   tags = {
  #     TerraformManaged = "true"
  #     Project          = var.project_name
  #     Environment      = var.environment_name
  #   }
  # }
}

locals {
  # Common tags that can be merged into resource tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment_name
    ManagedBy   = "Terraform"
  }
}

# Example of how you might use the common_tags with a resource in main.tf if you had one:
# resource "aws_s3_bucket" "example_bucket" {
#   bucket = "${var.project_name}-example-bucket-${var.environment_name}"
#   tags   = local.common_tags
# }
