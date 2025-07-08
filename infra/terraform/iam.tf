data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = var.lambda_iam_role_name != "" ? var.lambda_iam_role_name : "${var.project_name}-lambda-exec-role-${var.environment_name}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  path               = "/service-roles/"

  tags = merge(
    var.tags,
    {
      Name        = var.lambda_iam_role_name != "" ? var.lambda_iam_role_name : "${var.project_name}-lambda-exec-role-${var.environment_name}"
      Project     = var.project_name
      Environment = var.environment_name
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Example of an additional policy if needed in the future
# resource "aws_iam_policy" "lambda_custom_policy" {
#   name        = "${var.project_name}-lambda-custom-policy-${var.environment_name}"
#   description = "Custom permissions for the Lambda function"
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = [
#           "s3:GetObject"
#         ],
#         Effect   = "Allow",
#         Resource = "arn:aws:s3:::your-bucket-name/*"
#       }
#     ]
#   })
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-lambda-custom-policy-${var.environment_name}"
#       Project     = var.project_name
#       Environment = var.environment_name
#     }
#   )
# }

# resource "aws_iam_role_policy_attachment" "lambda_custom_policy_attachment" {
#   role       = aws_iam_role.lambda_exec_role.name
#   policy_arn = aws_iam_policy.lambda_custom_policy.arn
# }
