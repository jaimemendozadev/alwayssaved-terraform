resource "aws_sqs_queue" "extractor_push_queue" {
  name                       = "notecasts-extractor-push"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
  fifo_queue                 = false
}

resource "aws_sqs_queue" "extractor_pull_queue" {
  name                       = "notecasts-extractor-pull"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
  fifo_queue                 = false
}

output "extractor_push_queue_url" {
  value = aws_sqs_queue.extractor_push_queue.url
}

output "extractor_pull_queue_url" {
  value = aws_sqs_queue.extractor_pull_queue.url
}
