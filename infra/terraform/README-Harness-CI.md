# Harness CI/CD Integration Guide for Street Demo Lambda

This document provides a focused guide for configuring a CI/CD pipeline in Harness to deploy the "Street Demo" AWS Lambda function. The necessary AWS infrastructure (IAM Role, S3 Bucket, ECR Repository, placeholder Lambda Function, and Lambda Alias) is provisioned by the Terraform setup in this directory.

## 1. Key Terraform Outputs for Harness

Harness will consume the following outputs from the Terraform apply step. These should be made available to your Harness pipeline as variables (e.g., through Harness secrets management, Terraform Cloud/Enterprise integration, or by scripting `terraform output -json`).

*   **Lambda Function Identifiers:**
    *   `lambda_function_name`: Name of the Lambda function (e.g., `streetdemo-street-demo-dev`).
    *   `lambda_function_arn`: ARN of the Lambda function.
*   **Lambda Alias Identifiers:**
    *   `lambda_alias_name`: Name of the alias to target (e.g., `live`).
    *   `lambda_alias_arn`: ARN of the alias.
    *   `lambda_alias_invoke_arn`: Invoke ARN for the alias (recommended for triggers).
*   **IAM Role:**
    *   `lambda_iam_role_arn`: ARN of the execution role for the Lambda.
*   **S3 Bucket (for Zip Deployments):**
    *   `s3_lambda_artifacts_bucket_name`: Name of the S3 bucket.
*   **ECR Repository (for Container Deployments):**
    *   `ecr_repository_url`: Full URL of the ECR repository (e.g., `ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPO_NAME`).
    *   `ecr_repository_name`: Name of the ECR repository.
*   **AWS Region:**
    *   `aws_region`: The AWS region where resources are deployed (ensure this is an output from your `outputs.tf` or known to Harness).
    *(Note: `aws_region` was used in CI command examples but not explicitly added to `outputs.tf` earlier. Add it if not globally available in CI: `output "aws_region" { value = var.aws_region }`)*

## 2. Harness Deployment Workflow Overview

Terraform creates a placeholder Lambda function and an alias. Harness will then:

1.  **Build Artifact:**
    *   **Zip:** Create a `lambda_deploy_package.zip` from `street-demo/app.py` (and dependencies).
    *   **Container:** Build a Docker image from `street-demo/Dockerfile`.
2.  **Push/Upload Artifact:**
    *   **Zip:** Upload `lambda_deploy_package.zip` to the `s3_lambda_artifacts_bucket_name` with a versioned key (e.g., `lambda_artifacts/street_demo_v_BUILD_NUMBER.zip`).
    *   **Container:** Push the Docker image to `ecr_repository_url` with appropriate tags (e.g., `BUILD_NUMBER`, `latest`).
3.  **Deploy to AWS Lambda via Harness:**
    *   **Identify Function:** Target the `lambda_function_name`.
    *   **Update Code:**
        *   **Zip:** Configure Harness to update from S3, providing the `s3_lambda_artifacts_bucket_name` and the S3 key of the new zip.
        *   **Container:** Configure Harness to update from ECR, providing the `ImageURI` (e.g., `${ecr_repository_url}:BUILD_TAG`). Ensure Lambda `PackageType` is set to `Image`.
    *   **Publish New Version:** Instruct Harness to publish a new version of the Lambda function.
    *   **Update Alias:** Instruct Harness to update the `lambda_alias_name` to point to the newly published version.

## 3. Conceptual Harness Service/Pipeline Configuration Snippets

The following are conceptual examples of how you might structure information within Harness. The exact UI or YAML structure will depend on your Harness version and configuration.

### A. Lambda Service Definition in Harness

When defining a Lambda service in Harness, you'd typically specify how to fetch the code and basic configurations.

**For S3 Zip Deployment:**

*   **Function Name:** `${terraform.lambda_function_name}` (using Harness variable expression)
*   **Region:** `${terraform.aws_region}`
*   **Role ARN:** `${terraform.lambda_iam_role_arn}`
*   **Handler:** `app.handler`
*   **Runtime:** `python3.11`
*   **Deployment Package:** S3
    *   **S3 Bucket:** `${terraform.s3_lambda_artifacts_bucket_name}`
    *   **S3 Key:** `lambda_artifacts/street_demo_v_${artifact.buildNumber}.zip` (Harness expression for artifact version)

**For ECR Container Deployment:**

*   **Function Name:** `${terraform.lambda_function_name}`
*   **Region:** `${terraform.aws_region}`
*   **Role ARN:** `${terraform.lambda_iam_role_arn}`
*   **Package Type:** `Image`
*   **Image URI:** `${terraform.ecr_repository_url}:${artifact.tag}` (Harness expression for artifact tag)

### B. Harness Workflow Steps (Conceptual)

A Harness workflow might look like this:

1.  **Terraform Apply (Optional):** If managing Terraform via Harness, ensure infrastructure is up-to-date.
2.  **Build Artifact (Shell Script Step or dedicated Build Automation):**
    *   Commands as outlined in previous CI discussions to create `lambda_deploy_package.zip` or build/push Docker image.
3.  **Harness AWS Lambda Deploy Step:**
    *   **Function Setup:**
        *   Select Cloud Provider (AWS).
        *   Specify Region: `${terraform.aws_region}`.
        *   Function Name: `${terraform.lambda_function_name}`.
    *   **Deployment Strategy Specifics:**
        *   **If S3:**
            *   Source: S3
            *   S3 Bucket: `${terraform.s3_lambda_artifacts_bucket_name}`
            *   S3 Key: (Path to your uploaded zip, e.g., `lambda_artifacts/street_demo_v_${artifact.buildNumber}.zip`)
        *   **If ECR:**
            *   Source: ECR
            *   Image URI: `${terraform.ecr_repository_url}:${artifact.tag}`
            *   (Ensure Harness sets PackageType to Image if not already)
    *   **Publish Version:** `true`
    *   **Aliases to Update (Post-Publish):**
        *   Alias Name: `${terraform.lambda_alias_name}`
        *   Target Version: (Harness usually has an expression for the newly published version)

### C. Example JSON "Spec" for `update-function-code` (AWS CLI context, for understanding)

While Harness abstracts this, understanding the underlying AWS calls is useful.

**S3 Update:**
```json
// aws lambda update-function-code --cli-input-json file://update-s3.json
{
    "FunctionName": "streetdemo-street-demo-dev", // from terraform.lambda_function_name
    "S3Bucket": "streetdemo-lambda-artifacts-dev", // from terraform.s3_lambda_artifacts_bucket_name
    "S3Key": "lambda_artifacts/street_demo_v_123.zip", // CI generated
    "Publish": true,
    "Region": "us-east-1" // from terraform.aws_region
}
```

**ECR Update:**
```json
// aws lambda update-function-code --cli-input-json file://update-ecr.json
{
    "FunctionName": "streetdemo-street-demo-dev", // from terraform.lambda_function_name
    "ImageUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/streetdemo-lambda-dev:build-123", // from terraform.ecr_repository_url + tag
    "Publish": true,
    "Region": "us-east-1" // from terraform.aws_region
}
```
*(Note: If changing from Zip to Image, `update-function-configuration --package-type Image` might be needed first.)*

**Update Alias:**
```json
// aws lambda update-alias --cli-input-json file://update-alias.json
{
    "FunctionName": "streetdemo-street-demo-dev", // from terraform.lambda_function_name
    "Name": "live", // from terraform.lambda_alias_name
    "FunctionVersion": "NEW_VERSION_FROM_UPDATE_CODE_OUTPUT", // Captured from previous step
    "Region": "us-east-1" // from terraform.aws_region
}
```

## 4. Important Considerations

*   **Permissions:** Ensure the IAM role used by Harness has permissions to:
    *   `lambda:UpdateFunctionCode`
    *   `lambda:UpdateFunctionConfiguration`
    *   `lambda:PublishVersion`
    *   `lambda:UpdateAlias`
    *   `lambda:GetFunctionConfiguration` (and other read actions)
    *   `s3:GetObject` (for Lambda service to fetch zip from S3 if using that method)
    *   `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer` (for Lambda service to fetch image from ECR)
    *   STS GetCallerIdentity (often needed by Harness AWS connector)
*   **Terraform State:** Harness needs access to the Terraform outputs. Securely manage your Terraform state and how outputs are passed.
*   **First ECR Deployment:** When switching a Lambda from S3 (Zip) to ECR (Image) for the first time, ensure the `PackageType` is correctly updated to `Image`. Subsequent ECR deployments to an already image-configured Lambda are straightforward. The Terraform setup initializes the Lambda for S3 (Zip).

This guide should help bridge the gap between the Terraform-provisioned infrastructure and the Harness CI/CD pipeline configuration for your "Street Demo" Lambda. Remember to adapt specific expressions and names to match your Harness setup and artifact management.
