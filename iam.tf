#################################################
# Extractor Service
#################################################

# Principal = "ec2.amazonaws.com" -> Allows EC2 instances to use this role.
# sts:AssumeRole -> Lets EC2 instances temporarily "borrow" the role’s permissions.

# Original ec2 Role for Extractor Service
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

# Original ec2 IAM Policy for Extractor Service
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
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${var.aws_s3_code_bucket_name}/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::${var.aws_s3_code_bucket_name}"
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

# Original IAM Instance Profile for Extractor Service
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


#################################################
# Embedding Service
#################################################

# ec2 Role for Embedding Service 
resource "aws_iam_role" "always_saved_embedding_ec2_role" {
  name = "always-saved-embedding-ec2-role"

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

resource "aws_iam_role_policy_attachment" "attach_ssm_managed_policy_to_embedding" {
  role       = aws_iam_role.always_saved_embedding_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_agent_policy_to_embedding" {
  role       = aws_iam_role.always_saved_embedding_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ec2 IAM Policy for Embedding Service
resource "aws_iam_policy" "always_saved_embedding_ec2_policy" {
  name        = "AlwaysSavedEmbeddingEC2Policy"
  description = "Allows Embedding EC2 instances to access S3, SQS, and Parameter Store"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::${var.aws_s3_code_bucket_name}/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::${var.aws_s3_code_bucket_name}"
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

# IAM Instance Profile for Embedding Service
resource "aws_iam_role_policy_attachment" "attach_embedding_ec2_policy" {
  role       = aws_iam_role.always_saved_embedding_ec2_role.name
  policy_arn = aws_iam_policy.always_saved_embedding_ec2_policy.arn
}

resource "aws_iam_instance_profile" "always_saved_embedding_instance_profile" {
  name = "always-saved-embedding-instance-profile"
  role = aws_iam_role.always_saved_embedding_ec2_role.name
}


#################################################
# LLM Service
#################################################


# IAM Role for LLM EC2 Instance
resource "aws_iam_role" "always_saved_llm_ec2_role" {
  name = "always-saved-llm-ec2-role"

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

# Attach SSM Managed Policy for EC2 shell access
resource "aws_iam_role_policy_attachment" "attach_ssm_managed_policy_to_llm" {
  role       = aws_iam_role.always_saved_llm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent Policy for logs
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_agent_policy_to_llm" {
  role       = aws_iam_role.always_saved_llm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom IAM Policy for LLM EC2 (access to Qdrant, ECR, etc. — adjust as needed)
resource "aws_iam_policy" "always_saved_llm_ec2_policy" {
  name        = "AlwaysSavedLLMEC2Policy"
  description = "Grants LLM EC2 instance access to SSM, ECR, Qdrant, and basic network resources"

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
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach the custom policy
resource "aws_iam_role_policy_attachment" "attach_llm_ec2_policy" {
  role       = aws_iam_role.always_saved_llm_ec2_role.name
  policy_arn = aws_iam_policy.always_saved_llm_ec2_policy.arn
}

# IAM Instance Profile for LLM EC2
resource "aws_iam_instance_profile" "always_saved_llm_instance_profile" {
  name = "always-saved-llm-instance-profile"
  role = aws_iam_role.always_saved_llm_ec2_role.name
}




#################################################
# Next.js Frontend
#################################################

resource "aws_iam_role" "always_saved_frontend_ec2_role" {
  name = "always-saved-frontend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy_to_frontend" {
  role       = aws_iam_role.always_saved_frontend_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_to_frontend" {
  role       = aws_iam_role.always_saved_frontend_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "always_saved_frontend_ec2_policy" {
  name        = "AlwaysSavedFrontendEC2Policy"
  description = "Allows frontend EC2 to pull from ECR and read SSM secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource" : "arn:aws:s3:::${var.aws_s3_code_bucket_name}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : ["s3:ListBucket"],
        "Resource" : "arn:aws:s3:::${var.aws_s3_code_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource" : [
          "${aws_sqs_queue.extractor_push_queue.arn}",
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "sqs:ListQueues",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_frontend_custom_policy" {
  role       = aws_iam_role.always_saved_frontend_ec2_role.name
  policy_arn = aws_iam_policy.always_saved_frontend_ec2_policy.arn
}

resource "aws_iam_instance_profile" "always_saved_frontend_instance_profile" {
  name = "always-saved-frontend-instance-profile"
  role = aws_iam_role.always_saved_frontend_ec2_role.name
}
