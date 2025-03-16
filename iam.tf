resource "aws_iam_policy" "notecasts_ec2_policy" {
  name        = "NotecastsEC2Policy"
  description = "Allows EC2 instances to access S3, SQS, and Parameter Store"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::notecasts/*"
    },
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:us-east-1:${var.aws_account_id}:parameter/notecasts/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.notecasts_ec2_role.name
  policy_arn = aws_iam_policy.notecasts_ec2_policy.arn
}
