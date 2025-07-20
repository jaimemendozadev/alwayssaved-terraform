resource "aws_sqs_queue" "extractor_push_dlq" {
  name                      = "always-saved-extractor-push-dlq"
  message_retention_seconds = 1209600 # 14 days (max allowed)
}

resource "aws_sqs_queue" "extractor_push_queue" {
  name                       = "always-saved-extractor-push-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
  fifo_queue                 = false

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.extractor_push_dlq.arn,
    maxReceiveCount     = 5
  })

  tags = {
    Name = "always-saved-extractor-push-queue"
  }
}

resource "aws_sqs_queue" "embedding_push_queue" {
  name                       = "always-saved-embedding-push-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
  fifo_queue                 = false
}




output "extractor_push_queue_url" {
  value = aws_sqs_queue.extractor_push_queue.url
}

output "embedding_push_queue_url" {
  value = aws_sqs_queue.embedding_push_queue.url
}
output "extractor_push_dlq_url" {
  value = aws_sqs_queue.extractor_push_dlq.url
}