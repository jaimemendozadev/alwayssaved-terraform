# Principal = "ec2.amazonaws.com" -> Allows EC2 instances to use this role.
# sts:AssumeRole -> Lets EC2 instances temporarily "borrow" the role’s permissions.
resource "aws_iam_role" "notecasts_ec2_role" {
  name = "notecasts-ec2-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "notecasts_s3_access" {
  name        = "NotecastsS3AccessPolicy"
  description = "Allow EC2 instances to read/write from S3"

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
    }
  ]
}
EOF
}

# Attaches the S3 policy to the IAM role so the EC2 instance can access the S3 bucket.
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.notecasts_ec2_role.name
  policy_arn = aws_iam_policy.notecasts_s3_access.arn
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


resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  role       = aws_iam_role.notecasts_ec2_role.name
  policy_arn = aws_iam_policy.sqs_access_policy.arn
}


resource "aws_iam_policy" "ssm_access_policy" {
  name        = "NotecastsSSMAccessPolicy"
  description = "Allows EC2 instances to read SecureString parameters"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": [
        "arn:aws:ssm:us-east-1:YOUR_ACCOUNT_ID:parameter/notecasts/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.notecasts_ec2_role.name
  policy_arn = aws_iam_policy.ssm_access_policy.arn
}



# Creates an Instance Profile, which is required for EC2 instances to use IAM roles.
# Links the IAM Role `notecasts-ec2-role` to the profile.
resource "aws_iam_instance_profile" "notecasts_instance_profile" {
  name = "notecasts-instance-profile"
  role = aws_iam_role.notecasts_ec2_role.name
}
