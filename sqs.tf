
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


