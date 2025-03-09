
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

# Add permissions to allow the EC2 instance to send & receive messages
resource "aws_iam_policy" "sqs_access_policy" {
  name        = "NotecastsSQSAccessPolicy"
  description = "Allows EC2 instances to send & receive SQS messages"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "${aws_sqs_queue.extractor_push_queue.arn}",
        "${aws_sqs_queue.extractor_pull_queue.arn}"
      ]
    }
  ]
}
EOF
}

# Attach the SQS Policy to the EC2 IAM Role
resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  role       = aws_iam_role.notecasts_ec2_role.name
  policy_arn = aws_iam_policy.sqs_access_policy.arn
}

