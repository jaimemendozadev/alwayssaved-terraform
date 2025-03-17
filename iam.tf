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
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.notecasts_ec2_role.name
  policy_arn = aws_iam_policy.notecasts_ec2_policy.arn
}

# Creates an Instance Profile, which is required for EC2 instances to use IAM roles.
# Links the IAM Role `notecasts-ec2-role` to the profile.
resource "aws_iam_instance_profile" "notecasts_instance_profile" {
  name = "notecasts-instance-profile"
  role = aws_iam_role.notecasts_ec2_role.name
}


# 1️⃣ CodeDeploy needs its own IAM role to manage deployments.
resource "aws_iam_role" "notecasts_codedeploy_role" {
  name = "notecasts-codedeploy-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# 2️⃣ Attach CodeDeploy Service Role Policy
resource "aws_iam_role_policy_attachment" "attach_codedeploy_service_policy" {
  role       = aws_iam_role.notecasts_codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy_attachment" "attach_ssm_managed_policy" {
  role       = aws_iam_role.notecasts_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}