# Principal = "ec2.amazonaws.com" -> Allows EC2 instances to use this role.
# sts:AssumeRole -> Lets EC2 instances temporarily "borrow" the role’s permissions.
resource "aws_iam_role" "always_saved_ec2_role" {
  name = "always-saved-ec2-role"

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

resource "aws_iam_role_policy_attachment" "attach_ssm_managed_policy" {
  role       = aws_iam_role.always_saved_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_agent_policy" {
  role       = aws_iam_role.always_saved_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# TODO: Need to create a new /alwayssaved s3 Bucket
resource "aws_iam_policy" "always_saved_ec2_policy" {
  name        = "AlwaysSavedEC2Policy"
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
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::${var.aws_s3_code_bucket_name}/*"
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
        "${aws_sqs_queue.embedding_push_queue.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.always_saved_ec2_role.name
  policy_arn = aws_iam_policy.always_saved_ec2_policy.arn
}

# Creates an Instance Profile, which is required for EC2 instances to use IAM roles.
# Links the IAM Role `always-saved-ec2-role` to the profile.
resource "aws_iam_instance_profile" "always_saved_instance_profile" {
  name = "always-saved-instance-profile"
  role = aws_iam_role.always_saved_ec2_role.name
}

