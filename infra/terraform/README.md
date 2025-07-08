# Terraform Infrastructure for AWS Lambda Street Demo

This Terraform configuration provisions the necessary AWS infrastructure to support the "Street Demo" Lambda function. It sets up a flexible foundation allowing the Lambda to be deployed either as a **Zip package from S3** or as a **Container Image from ECR**. The deployment and updates of the Lambda function code are expected to be managed by a CI/CD system like Harness.

## Overview

The primary goal of this Terraform setup is to manage the foundational AWS resources:

1.  **IAM Role**: An IAM execution role for the Lambda function, granting basic CloudWatch logging permissions.
2.  **S3 Bucket**: An S3 bucket for storing Lambda zip deployment packages.
3.  **ECR Repository**: An Elastic Container Registry (ECR) repository for storing Lambda Docker images.
4.  **AWS Lambda Function (Placeholder)**: An initial AWS Lambda function is created by Terraform.
    *   Its code is sourced from a **dummy zip file** (`dummy_lambda_payload.zip`) uploaded by Terraform to the S3 bucket. This serves as a placeholder.
    *   This allows Harness to have an existing function to target for updates.
5.  **AWS Lambda Alias**: A Lambda alias (e.g., `live`) is created, pointing to the initial version of the placeholder function. This provides a stable endpoint for invocation.

The CI/CD system (Harness) will then be responsible for:
*   Building the actual Lambda code (either as a zip or a Docker image).
*   Uploading the artifact to the S3 bucket or ECR repository.
*   Updating the Lambda function's code source to point to the new artifact (either S3 object or ECR image URI).
*   Publishing a new version of the Lambda function.
*   Updating the Lambda alias to point to the new version.

## Resources Created

*   **AWS IAM Role (`lambda_exec_role`)**:
    *   Named using `project_name` and `environment_name`.
    *   Grants `AWSLambdaBasicExecutionRole` for CloudWatch logging.
    *   Trusts `lambda.amazonaws.com`.
*   **AWS S3 Bucket (`lambda_artifacts`)**:
    *   Named using `project_name` and `environment_name`.
    *   Versioning enabled.
    *   Private access with public access blocked.
*   **AWS ECR Repository (`lambda_repo`)**:
    *   Named using `project_name` and `environment_name`.
    *   Image scanning on push enabled.
    *   Image tag mutability is `MUTABLE` by default.
*   **AWS S3 Object (`dummy_lambda_zip`)**:
    *   Uploads `dummy_lambda_payload.zip` to the `lambda_artifacts` S3 bucket. This is the initial code for the Lambda.
*   **AWS Lambda Function (`street_demo_lambda`)**:
    *   Named using `project_name` and `environment_name`.
    *   Uses the `lambda_exec_role`.
    *   Handler: `app.handler`, Runtime: `python3.11`.
    *   Initial code sourced from `dummy_lambda_zip` in S3.
    *   Configured with initial environment variables.
    *   `publish = true` to create an initial version.
*   **AWS Lambda Alias (`demo_alias`)**:
    *   Name: `live` (by default).
    *   Points to the initial published version of `street_demo_lambda`.

## Prerequisites

*   Terraform (`>= 1.0`).
*   AWS Account and properly configured AWS credentials for Terraform.
*   A local `dummy_lambda_payload.zip` file in the `infra/terraform` directory *before* running `terraform apply`. This zip should contain a minimal `app.py` (or the handler path in `lambda.tf` must be adjusted accordingly, e.g., `dummy_app.handler` if the file inside the zip is `dummy_app.py`).

    **To create a suitable `dummy_lambda_payload.zip`:**
    1. Create a file named `app.py` (or `dummy_app.py`) with the following content:
       ```python
       import json
       def handler(event, context):
           print("Dummy handler from Terraform initial deploy")
           return {
               "statusCode": 200,
               "body": json.dumps({"message": "Dummy Handler from Terraform initial deploy"})
           }
       ```
    2. Zip this file, ensuring it's at the root of the archive if your handler is `app.handler`:
       ```bash
       # In a temporary directory or directly:
       # If you created dummy_app.py and want app.handler:
       # cp dummy_app.py app.py
       # zip dummy_lambda_payload.zip app.py
       # rm app.py # optional cleanup
       # Ensure dummy_lambda_payload.zip is in infra/terraform/
       ```
       If `dummy_lambda_payload.zip` contains `dummy_app.py`, then the handler in `lambda.tf` should be `dummy_app.handler`. The current `lambda.tf` assumes `app.handler`.

## Usage

1.  **Navigate to the Terraform directory**:
    ```bash
    cd infra/terraform
    ```
2.  **Prepare `dummy_lambda_payload.zip`**: Create this file as described in Prerequisites and place it in the current directory (`infra/terraform/`).

3.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

4.  **Review Plan**:
    ```bash
    terraform plan -var="project_name=myproject" -var="environment_name=dev"
    ```
    *(Adjust variables as needed, or use a `.tfvars` file)*

5.  **Apply Changes**:
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

| Name                            | Description                                                                 |
| ------------------------------- | --------------------------------------------------------------------------- |
| `lambda_iam_role_arn`           | The ARN of the IAM role created for the Lambda function.                    |
| `lambda_iam_role_name`          | The Name of the IAM role created for the Lambda function.                   |
| `ecr_repository_url`            | The URL of the ECR repository created for Lambda images.                    |
| `ecr_repository_name`           | The name of the ECR repository created for Lambda images.                   |
| `s3_lambda_artifacts_bucket_name` | The name of the S3 bucket for Lambda artifacts.                           |
| `s3_lambda_artifacts_bucket_arn`  | The ARN of the S3 bucket for Lambda artifacts.                              |
| `s3_lambda_artifacts_bucket_id`   | The ID (name) of the S3 bucket for Lambda artifacts.                      |
| `lambda_function_name`          | The name of the created AWS Lambda function.                                |
| `lambda_function_arn`           | The ARN of the created AWS Lambda function.                                 |
| `lambda_function_qualified_arn` | The qualified ARN of the initial version of the AWS Lambda function.        |
| `lambda_function_invoke_arn`    | The invoke ARN of the created AWS Lambda function.                          |
| `lambda_alias_name`             | The name of the Lambda alias (e.g., `live`).                                |
| `lambda_alias_arn`              | The ARN of the Lambda alias.                                                |
| `lambda_alias_invoke_arn`       | The Invoke ARN of the Lambda alias (recommended for function invocation).   |

### Example: Using Outputs in Harness for Lambda Deployment

Harness will use these outputs to target the AWS resources for deploying the "Street Demo" Lambda:

1.  **Identify Target Lambda**:
    *   Use `lambda_function_name` or `lambda_function_arn` to identify the Lambda function to update.
    *   Use `lambda_alias_name` or `lambda_alias_arn` to identify the alias to update after publishing a new version.

2.  **For S3 (Zip) Deployments:**
    *   Your CI process will build the `street-demo/app.py` into a zip file.
    *   Upload this zip to the bucket identified by `s3_lambda_artifacts_bucket_name` (e.g., to a key like `lambda_artifacts/street_demo_payload_v_BUILD_NUMBER.zip`).
    *   In Harness:
        *   Configure the Lambda deployment step to update the code from S3.
        *   Set the S3 bucket to `s3_lambda_artifacts_bucket_name`.
        *   Set the S3 key to the path of your newly uploaded zip.
        *   Publish a new version.
        *   Update the alias (`lambda_alias_name`) to point to this new published version.

3.  **For ECR (Container) Deployments:**
    *   Your CI process will build a Docker image from `street-demo/Dockerfile`.
    *   Push this image to the ECR repository identified by `ecr_repository_url` (or `ecr_repository_name`), tagging it appropriately (e.g., `BUILD_NUMBER`, `latest`).
    *   In Harness:
        *   Configure the Lambda deployment step to update the code from an ECR image.
        *   Set the Image URI to `${ecr_repository_url}:TAG`.
        *   Change the Lambda's package type to `Image` if it was previously `Zip`.
        *   Publish a new version.
        *   Update the alias (`lambda_alias_name`) to point to this new published version.

4.  **IAM Role**:
    *   The Lambda function is initially configured by Terraform to use `lambda_iam_role_arn`. Harness should generally not need to change this unless the deployment process itself modifies the role or function in a way that detaches it.

This comprehensive setup allows Terraform to lay down a stable, well-defined foundation, and Harness to flexibly manage the application code lifecycle using either deployment strategy.
