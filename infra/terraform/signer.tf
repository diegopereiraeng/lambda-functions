variable "signer_profile_name_infra" { # Renamed to avoid conflict if used in post-deploy TF too
  description = "Name for the AWS Signer signing profile created by infrastructure Terraform."
  type        = string
  default     = "" # If empty, generated: ${var.project_name}-lambda-signing-profile-${var.environment_name}
}

resource "aws_signer_signing_profile" "lambda_signing_profile_infra" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = var.signer_profile_name_infra != "" ? var.signer_profile_name_infra : "${var.project_name}-lambda-signing-profile-${var.environment_name}"

  tags = merge(
    local.common_tags,
    {
      Name = var.signer_profile_name_infra != "" ? var.signer_profile_name_infra : "${var.project_name}-lambda-signing-profile-${var.environment_name}"
    }
  )
}
