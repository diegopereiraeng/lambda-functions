resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "${var.project_name}-lambda-artifacts-${var.environment_name}" # Ensure this is globally unique if needed, or add random suffix.
  # acl    = "private" # Deprecated, use aws_s3_bucket_acl or preferably bucket policies and IAM.

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-lambda-artifacts-${var.environment_name}"
      Project     = var.project_name
      Environment = var.environment_name
    }
  )
}

resource "aws_s3_bucket_acl" "lambda_artifacts_acl" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  acl    = "private" # Sets the Canned ACL to private
}

resource "aws_s3_bucket_versioning" "lambda_artifacts_versioning" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  configuration {
    status = "Enabled"
  }
}

# Block public access by default - recommended
resource "aws_s3_bucket_public_access_block" "lambda_artifacts_public_access" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
