terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Specify a version constraint
    }
  }
  required_version = ">= 1.0" # Specify Terraform version constraint
}

# Provider configuration will be in main.tf, referencing variables for region
# This keeps provider-specific configuration separate from declarations.
