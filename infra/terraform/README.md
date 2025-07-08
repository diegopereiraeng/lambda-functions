# Terraform Infrastructure for Lambda Function

This Terraform configuration provisions the necessary AWS infrastructure to support a Lambda function that will be deployed and managed by a CI/CD system like Harness.

## Overview

The primary goal of this Terraform setup is to manage the foundational AWS resources that the Lambda function relies on, specifically:

1.  **IAM Role**: An IAM execution role for the Lambda function, granting it permissions to write logs to CloudWatch.
2.  **ECR Repository**: An Elastic Container Registry (ECR) repository where Docker images for the Lambda function will be stored.

The Lambda function code itself, its packaging into a Docker image, and the deployment of the `aws_lambda_function` resource (including its configuration like memory, timeout, environment variables, and pointing to the ECR image) are expected to be handled by an external CI/CD system (e.g., Harness).

## Resources Created

*   **AWS IAM Role**:
    *   Named according to the `project_name` and `environment_name` variables (or `lambda_iam_role_name` if specified).
    *   Grants `AWSLambdaBasicExecutionRole` permissions for CloudWatch logging.
    *   Trusts the `lambda.amazonaws.com` service principal.
*   **AWS ECR Repository**:
    *   Named according to the `project_name` and `environment_name` variables (or `ecr_repository_name` if specified).
    *   Configured for image scanning on push.
    *   Image tag mutability is set (default: `MUTABLE`).

## Prerequisites

*   Terraform (>= 1.0)
*   AWS Account and properly configured AWS credentials for Terraform.

## Usage

1.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

2.  **Review Plan**:
    ```bash
    terraform plan -var="project_name=myproject" -var="environment_name=dev"
    ```
    *(Adjust variables as needed, or use a `.tfvars` file)*

3.  **Apply Changes**:
    ```bash
    terraform apply -var="project_name=myproject" -var="environment_name=dev"
    ```

## Inputs

| Name                    | Description                                                                 | Type        | Default     |
| ----------------------- | --------------------------------------------------------------------------- | ----------- | ----------- |
| `aws_region`            | The AWS region where resources will be created.                             | `string`    | `us-east-1` |
| `project_name`          | A name for the project, used for tagging and naming resources.              | `string`    | `streetdemo`|
| `environment_name`      | The environment name (e.g., dev, staging, prod).                            | `string`    | `dev`       |
| `lambda_iam_role_name`  | Custom name for the Lambda IAM role. If not set, a name will be generated.  | `string`    | `""`        |
| `ecr_repository_name`   | Custom name for the ECR repository. If not set, a name will be generated. | `string`    | `""`        |
| `tags`                  | A map of additional tags to assign to created resources.                    | `map(string)` | `{}`        |

## Outputs

These outputs are intended to be consumed by a CI/CD system (like Harness) to configure and deploy the Lambda function:

| Name                    | Description                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| `lambda_iam_role_arn`   | The ARN of the IAM role created for the Lambda function.         |
| `lambda_iam_role_name`  | The Name of the IAM role created for the Lambda function.        |
| `ecr_repository_url`    | The URL of the ECR repository created for Lambda images.         |
| `ecr_repository_name`   | The name of the ECR repository created for Lambda images.        |

### Example: Using Outputs in Harness

In Harness, you would configure your Lambda deployment steps to:
1.  Use the `ecr_repository_url` (or `ecr_repository_name`) as the target for pushing the Docker image built by Harness.
2.  Use the `lambda_iam_role_arn` as the execution role for the Lambda function when Harness creates or updates it.

This separation of concerns allows Terraform to manage the stable infrastructure components while Harness handles the application deployment lifecycle.
