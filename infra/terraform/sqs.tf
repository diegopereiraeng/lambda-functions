variable "sqs_queue_name" {
  description = "Name for the SQS queue."
  type        = string
  default     = "" # If empty, a name will be generated
}

variable "sqs_message_retention_seconds" {
  description = "The visibility timeout for the queue. An integer from 0 to 43200 (12 hours)."
  type        = number
  default     = 300 # 5 minutes
}

resource "aws_sqs_queue" "lambda_event_source_queue" {
  name                        = var.sqs_queue_name != "" ? var.sqs_queue_name : "${var.project_name}-lambda-queue-${var.environment_name}"
  delay_seconds               = 0
  max_message_size            = 262144 # 256 KiB
  message_retention_seconds   = var.sqs_message_retention_seconds
  receive_wait_time_seconds   = 10 # Enable long polling
  # For a standard queue, content_based_deduplication and fifo_queue are not applicable or false by default.

  tags = merge(
    local.common_tags,
    {
      Name = var.sqs_queue_name != "" ? var.sqs_queue_name : "${var.project_name}-lambda-queue-${var.environment_name}"
    }
  )
}

# Policy allowing Lambda service to read from this SQS queue (less critical if using lambda event source mapping, which sets this up)
# However, it's good practice if other services might also need to interact with the queue policy directly.
# For Lambda event source mapping, the necessary permissions are typically added by AWS to the Lambda's execution role,
# or to the queue policy if the Lambda role is from a different account.
# The aws_lambda_event_source_mapping resource itself handles the necessary permissions.

# output "sqs_queue_arn" {
#   description = "ARN of the SQS queue."
#   value       = aws_sqs_queue.lambda_event_source_queue.arn
# }

# output "sqs_queue_url" {
#   description = "URL of the SQS queue."
#   value       = aws_sqs_queue.lambda_event_source_queue.id # .id is the URL for SQS queues
# }

# output "sqs_queue_name" {
#   description = "Name of the SQS queue."
#   value       = aws_sqs_queue.lambda_event_source_queue.name
# }
