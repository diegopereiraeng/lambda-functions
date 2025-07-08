resource "aws_ecr_repository" "lambda_repo" {
  name                 = var.ecr_repository_name != "" ? var.ecr_repository_name : "${var.project_name}-lambda-${var.environment_name}"
  image_tag_mutability = "MUTABLE" # Or "IMMUTABLE" based on your strategy

  image_scanning_configuration {
    scan_on_push = true
  }

  # Optional: Lifecycle policy to clean up old images
  # lifecycle_policy = jsonencode({
  #   rules = [
  #     {
  #       rulePriority = 1,
  #       description  = "Keep only last 10 images",
  #       selection = {
  #         tagStatus     = "any",
  #         countType     = "imageCountMoreThan",
  #         countNumber   = 10
  #       },
  #       action = {
  #         type = "expire"
  #       }
  #     }
  #   ]
  # })

  tags = merge(
    var.tags,
    {
      Name        = var.ecr_repository_name != "" ? var.ecr_repository_name : "${var.project_name}-lambda-${var.environment_name}"
      Project     = var.project_name
      Environment = var.environment_name
    }
  )
}

# Optional: ECR Repository Policy (e.g., to allow other accounts to pull)
# resource "aws_ecr_repository_policy" "lambda_repo_policy" {
#   repository = aws_ecr_repository.lambda_repo.name
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid    = "AllowCrossAccountPull",
#         Effect = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::OTHER_ACCOUNT_ID:root"
#         },
#         Action = [
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "ecr:BatchCheckLayerAvailability"
#         ]
#       }
#     ]
#   })
# }
