# Step-by-Step Guide: Integrating AWS Lambda Deployment with Harness and Terraform

This guide demonstrates how to manage AWS Lambda functions where Terraform defines the core infrastructure (including the Lambda function's configuration and associated resources), and Harness CI/CD pipelines are responsible for deploying and updating the Lambda function's code. We'll also cover passing necessary information between Terraform and Harness.

**Core Principles:**

*   **Terraform as Source of Truth for Infrastructure:** Terraform defines *what* resources exist and their configuration (IAM roles, Lambda settings like memory/timeout, event sources, permissions, concurrency, code signing).
*   **Harness for Code Deployment Lifecycle:** Harness manages the CI/CD process for the Lambda function *code*, updating the function defined by Terraform.
*   **Clear Data Exchange:** Use AWS Systems Manager (SSM) Parameter Store for sharing outputs (like Lambda ARNs or versions) from Harness back to Terraform if needed.

**Scenario: Managing a Lambda Function (e.g., part of an EC2 Patch Manager module)**

**Step 1: Terraform - Define the Lambda Function and Associated Resources**

Your Terraform module (e.g., `afp_terraform-aws-ec2-patch-manager` or a new dedicated module) will define the Lambda function and all its related AWS infrastructure.

*   **`lambda.tf` (Illustrative example within your module):**

    ```terraform
    variable "lambda_function_name" {
      description = "The name of the Lambda function."
      type        = string
      default     = "MyApplicationLambda" # Example: "ec2-patch-manager"
    }

    variable "lambda_handler" {
      description = "The Lambda function handler."
      type        = string
      default     = "index.handler"
    }

    variable "lambda_runtime" {
      description = "The Lambda function runtime."
      type        = string
      default     = "python3.9"
    }

    variable "lambda_memory_size" {
      description = "Memory for the Lambda function."
      type        = number
      default     = 256
    }

    variable "lambda_timeout" {
      description = "Timeout for the Lambda function."
      type        = number
      default     = 60 # seconds
    }

    variable "subnet_ids" {
      description = "List of subnet IDs for Lambda VPC configuration."
      type        = list(string)
      default     = [] # Pass these in if your Lambda needs VPC access
    }

    variable "security_group_ids" {
      description = "List of security group IDs for Lambda VPC configuration."
      type        = list(string)
      default     = [] # Pass these in if your Lambda needs VPC access
    }

    variable "environment_variables" {
      description = "Environment variables for the Lambda function."
      type        = map(string)
      default     = {}
    }

    variable "initial_code_s3_bucket" {
      description = "S3 bucket for the initial Lambda code package (optional)."
      type        = string
      default     = null
    }

    variable "initial_code_s3_key" {
      description = "S3 key for the initial Lambda code package (optional)."
      type        = string
      default     = null
    }

    variable "enable_provisioned_concurrency" {
      description = "Flag to enable provisioned concurrency."
      type        = bool
      default     = false
    }

    variable "provisioned_concurrency_alias_name" {
      description = "Alias name for provisioned concurrency (e.g., 'live'). Harness will update this alias."
      type        = string
      default     = "live"
    }

    variable "code_signing_config_arn" {
      description = "ARN of the Code Signing Configuration for the Lambda (optional)."
      type        = string
      default     = null
    }

    # IAM Role for Lambda Execution
    resource "aws_iam_role" "lambda_exec_role" {
      name = "${var.lambda_function_name}-exec-role"
      assume_role_policy = jsonencode({
        Version   = "2012-10-17"
        Statement = [{
          Action    = "sts:AssumeRole"
          Effect    = "Allow"
          Principal = { Service = "lambda.amazonaws.com" }
        }]
      })
      # Attach policies: AWSLambdaBasicExecutionRole and any other necessary permissions
      managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
      # Add more policies or inline policies as needed
    }

    # Lambda Function Resource
    resource "aws_lambda_function" "this" {
      function_name = var.lambda_function_name
      handler       = var.lambda_handler
      runtime       = var.lambda_runtime
      role          = aws_iam_role.lambda_exec_role.arn
      memory_size   = var.lambda_memory_size
      timeout       = var.lambda_timeout
      publish       = true # Important: Allows Harness to work with versions and aliases

      s3_bucket = var.initial_code_s3_bucket # For initial deployment by Terraform
      s3_key    = var.initial_code_s3_key    # Harness will update the code later

      dynamic "vpc_config" {
        for_each = length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0 ? [1] : []
        content {
          subnet_ids         = var.subnet_ids
          security_group_ids = var.security_group_ids
        }
      }

      environment {
        variables = var.environment_variables
      }

      code_signing_config_arn = var.code_signing_config_arn
    }

    # Alias for stable endpoint (e.g., 'live') - Harness will update this
    resource "aws_lambda_alias" "this" {
      name             = var.provisioned_concurrency_alias_name # e.g., "live"
      description      = "Stable alias for the function"
      function_name    = aws_lambda_function.this.function_name
      function_version = "$LATEST" # Terraform initially points to $LATEST; Harness will update this to specific versions
                                  # Or, point to aws_lambda_function.this.version if you want to pin the initial alias
    }

    # Provisioned Concurrency (Example - attached to the alias Harness manages)
    resource "aws_lambda_provisioned_concurrency_config" "this" {
      count = var.enable_provisioned_concurrency ? 1 : 0

      function_name                     = aws_lambda_function.this.function_name
      provisioned_concurrent_executions = 5 # Or make this a variable
      qualifier                         = aws_lambda_alias.this.name
    }

    # Example: CloudWatch Event Rule to trigger the Lambda (e.g., a schedule)
    resource "aws_cloudwatch_event_rule" "schedule" {
      count               = 1 # Condition this if the trigger is optional
      name                = "${var.lambda_function_name}-schedule"
      description         = "Scheduled trigger for ${var.lambda_function_name}"
      schedule_expression = "rate(1 day)" # Example: runs once a day
    }

    resource "aws_cloudwatch_event_target" "lambda_target" {
      count     = 1 # Condition this if the trigger is optional
      rule      = aws_cloudwatch_event_rule.schedule[0].name
      target_id = var.lambda_function_name
      arn       = aws_lambda_alias.this.arn # Trigger the alias
    }

    resource "aws_lambda_permission" "allow_cloudwatch" {
      count         = 1 # Condition this if the trigger is optional
      statement_id  = "AllowExecutionFromCloudWatch"
      action        = "lambda:InvokeFunction"
      function_name = aws_lambda_function.this.function_name
      principal     = "events.amazonaws.com"
      source_arn    = aws_cloudwatch_event_rule.schedule[0].arn
      qualifier     = aws_lambda_alias.this.name # Grant permission to the alias
    }

    # Outputs from Terraform (can be used as inputs to Harness if needed, e.g., via API or manual entry)
    output "lambda_function_name" {
      value = aws_lambda_function.this.function_name
    }

    output "lambda_function_arn" {
      value = aws_lambda_function.this.arn
    }

    output "lambda_alias_name" {
      value = aws_lambda_alias.this.name
    }

    output "lambda_alias_arn" {
      value = aws_lambda_alias.this.arn
    }

    output "lambda_iam_role_arn" {
      value = aws_iam_role.lambda_exec_role.arn
    }
    ```

*   **Apply Terraform:**
    `terraform init`
    `terraform apply`
    This creates the Lambda function with its initial configuration, IAM role, alias, and any event sources.

**Step 2: Harness - Configure CI/CD Pipeline for Lambda Code Deployment**

This assumes you have an artifact (e.g., a zip file of your Lambda code) produced by a CI build process or available in S3/Artifactory.

1.  **Set up Harness AWS Connector:**
    *   In Harness, navigate to **Project Setup** -> **Connectors**.
    *   Create an **AWS Connector** with appropriate permissions to:
        *   Describe and update Lambda functions, versions, and aliases.
        *   (If writing to SSM) `ssm:PutParameter`, `ssm:GetParameter`, `ssm:DescribeParameters`.
        *   Access your artifact repository (e.g., S3 read access).

2.  **Create a Harness Service:**
    *   Go to **Services**.
    *   Click **+ New Service**, name it (e.g., `MyApplicationLambdaService`).
    *   **Deployment Type:** AWS Lambda.
    *   **Artifacts:**
        *   Click **+ Add Artifact Source**.
        *   Choose your artifact repository (e.g., S3, Artifactory, Jenkins).
        *   Configure it to point to your Lambda code package (zip file). Make sure it can pick up new versions.

3.  **Create a Harness Environment and Infrastructure Definition:**
    *   Go to **Environments**.
    *   Click **+ New Environment**, name it (e.g., `dev`, `staging`).
    *   Inside the Environment, click **+ Infrastructure Definition**.
        *   Name it (e.g., `AWSLambdaInfra`).
        *   **Deployment Type:** AWS Lambda.
        *   **Cloud Provider:** Select your AWS Connector.
        *   **Region:** Select the AWS region where your Lambda is deployed.

4.  **Create the Deployment Pipeline:**
    *   Go to **Pipelines**.
    *   Click **+ Create Pipeline**, name it (e.g., `DeployMyApplicationLambda`).
    *   Add a **Deploy** stage.
        *   **Service:** Select the Service you created (`MyApplicationLambdaService`).
        *   **Infrastructure:** Select the Environment and Infrastructure Definition.
        *   **Execution Strategy:**
            *   Select **AWS Lambda**.
            *   Click **+ Add Step** -> **AWS Lambda** (this is the main deployment step).
            *   **Configuration for the "AWS Lambda" step:**
                *   **Function Name:** `<+infra.variables.function_name>` (if you define it as an infra variable) or directly enter the function name defined in Terraform (e.g., `MyApplicationLambda`). **This must match the `function_name` in your Terraform `aws_lambda_function` resource.**
                *   **Runtime Parameters (Optional):** You can often override memory, timeout here, but be cautious. If Terraform defines these, overriding in Harness can cause drift. For this hybrid pattern, it's best if Harness *only* updates the code and alias.
                *   **Lambda Function Packaging Options:**
                    *   **Package Type:** Usually `Zip File`.
                    *   **Artifact:** Select the artifact you defined in the Service.
                *   **Deployment Options:**
                    *   **Publish new version:** **Enable this.**
                *   **Alias Management:**
                    *   **Update Aliases:** **Enable this.**
                    *   **Alias Name:** Enter the alias name you defined in Terraform (e.g., `live`).
                    *   **Target Version:** Select an option like `Newly published version`. This tells Harness to point the alias to the version it just deployed.

        *   **(Optional but Recommended) Add a Shell Script step to output Lambda info to SSM:**
            *   After the "AWS Lambda" deployment step, add a **Shell Script** step.
            *   Name: `Output Lambda Info to SSM`.
            *   **Script:**
                ```bash
                # These values should ideally come from Harness expressions if available,
                # or be consistent with your Lambda step configuration.
                # Ensure to replace placeholders or use actual Harness expressions.
                FUNCTION_NAME_FROM_HARNESS_STEP="MyApplicationLambda" # Example: <+serviceConfig.awsLambda.functionName> or from a prior step output
                ALIAS_NAME_FROM_HARNESS_STEP="live" # Example: <+serviceConfig.awsLambda.aliases[0].name>
                AWS_REGION_FROM_HARNESS_INFRA="us-east-1" # Example: <+infra.region>

                echo "Fetching ARN for function: $FUNCTION_NAME_FROM_HARNESS_STEP, alias: $ALIAS_NAME_FROM_HARNESS_STEP in region $AWS_REGION_FROM_HARNESS_INFRA"

                # Get the ARN of the alias (which points to the specific version deployed by Harness)
                ALIAS_ARN=$(aws lambda get-alias --function-name "$FUNCTION_NAME_FROM_HARNESS_STEP" --name "$ALIAS_NAME_FROM_HARNESS_STEP" --region "$AWS_REGION_FROM_HARNESS_INFRA" --query 'AliasArn' --output text)
                FUNCTION_VERSION=$(aws lambda get-alias --function-name "$FUNCTION_NAME_FROM_HARNESS_STEP" --name "$ALIAS_NAME_FROM_HARNESS_STEP" --region "$AWS_REGION_FROM_HARNESS_INFRA" --query 'FunctionVersion' --output text)

                if [ -z "$ALIAS_ARN" ]; then
                  echo "Error: Could not retrieve Alias ARN."
                  exit 1
                fi

                echo "Alias ARN: $ALIAS_ARN"
                echo "Function Version for Alias: $FUNCTION_VERSION"

                # Write to SSM Parameter Store - ensure parameter names are unique and descriptive
                aws ssm put-parameter --name "/app/${FUNCTION_NAME_FROM_HARNESS_STEP}/alias/${ALIAS_NAME_FROM_HARNESS_STEP}/arn" --value "$ALIAS_ARN" --type String --overwrite --region "$AWS_REGION_FROM_HARNESS_INFRA"
                aws ssm put-parameter --name "/app/${FUNCTION_NAME_FROM_HARNESS_STEP}/alias/${ALIAS_NAME_FROM_HARNESS_STEP}/version" --value "$FUNCTION_VERSION" --type String --overwrite --region "$AWS_REGION_FROM_HARNESS_INFRA"

                echo "Lambda alias ARN and version written to SSM."
                ```
            *   **Delegate Selector:** Ensure this script runs on a delegate that has the AWS CLI installed and the necessary IAM permissions (via the AWS Connector or delegate's instance profile for `lambda:GetAlias` and `ssm:PutParameter`).

5.  **Run the Harness Pipeline:**
    *   Trigger the pipeline. It will fetch the specified artifact, deploy it to the existing Lambda function (updating its code), publish a new version, and update the specified alias to point to this new version. The script step will then write the alias ARN and version to SSM.

**Step 3: Terraform - Consuming Outputs from Harness (Optional)**

If other Terraform resources need to know the specific Lambda ARN or version deployed by Harness (e.g., an API Gateway integration that must point to a specific alias ARN updated by Harness).

*   **`api_gateway.tf` (Illustrative example):**

    ```terraform
    # Data source to read the Lambda alias ARN written by Harness to SSM
    data "aws_ssm_parameter" "lambda_alias_arn" {
      # Ensure the name matches what Harness writes
      # Example: /app/MyApplicationLambda/alias/live/arn
      name = "/app/${var.lambda_function_name}/alias/${var.provisioned_concurrency_alias_name}/arn"
    }

    # Example: API Gateway Integration
    # resource "aws_api_gateway_rest_api" "api" { ... }
    # resource "aws_api_gateway_resource" "proxy" { ... }
    # resource "aws_api_gateway_method" "proxy_method" { ... }

    # resource "aws_api_gateway_integration" "lambda_integration" {
    #   rest_api_id = aws_api_gateway_rest_api.api.id
    #   resource_id = aws_api_gateway_resource.proxy.id
    #   http_method = aws_api_gateway_method.proxy_method.http_method
    #   type        = "AWS_PROXY"
    #   integration_http_method = "POST" # For AWS_PROXY
    #
    #   # Use the ARN of the alias managed by Harness
    #   # You might need to fetch region from data "aws_region" "current" {}
    #   uri = "arn:aws:apigateway:YOUR_AWS_REGION:lambda:path/2015-03-31/functions/${data.aws_ssm_parameter.lambda_alias_arn.value}/invocations"
    # }
    ```

*   **Apply Terraform (after Harness run):**
    `terraform apply`
    Terraform will now use the Lambda alias ARN fetched from SSM.

**Step 4: Passing Inputs to Harness (e.g., Subnets, Security Groups for Lambda VPC)**

If Harness were *creating* the Lambda (not the hybrid approach), or if you wanted Harness to *update* VPC settings (use with caution if Terraform also defines them):

1.  **Terraform Side:**
    *   Output the necessary values:
        ```terraform
        output "vpc_subnet_ids" {
          value = module.vpc.private_subnets # Example
        }
        output "vpc_security_group_ids" {
          value = [aws_security_group.lambda_sg.id] # Example
        }
        ```
2.  **Harness Side:**
    *   **Define Pipeline Variables:** In your Harness pipeline settings, define variables (e.g., `SUBNET_IDS`, `SG_IDS`).
    *   **Populate Variables:**
        *   **Manually:** Enter them when running the pipeline.
        *   **Trigger with Parameters:** If triggering Harness via API, pass them in the payload.
        *   **From S3/SSM (Advanced):** A script step in Harness could read these if Terraform wrote them to a known location.
    *   **Use in Lambda Step:** In the Harness "AWS Lambda" deployment step, if it has fields for VPC configuration, use expressions like `<+pipeline.variables.SUBNET_IDS>`. (Note: In our hybrid approach, Terraform defines VPC, so Harness wouldn't typically set this).

---

This detailed guide should provide a solid framework for integrating your Lambda deployments with Harness and Terraform using the recommended hybrid approach. Remember to adapt names, paths, and specific configurations to your environment. Pay close attention to using actual Harness expressions for variables like function name, alias, and region within the shell script step if possible, or ensure consistency if hardcoding.
