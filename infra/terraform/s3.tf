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

resource "aws_s3_bucket_ownership_controls" "lambda_artifacts_ownership" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket.lambda_artifacts] # Ensure bucket exists before applying ownership
}

resource "aws_s3_bucket_versioning" "lambda_artifacts_versioning" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  versioning_configuration {
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
