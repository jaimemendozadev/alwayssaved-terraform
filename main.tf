resource "aws_iam_role" "notecasts_role" {
  name = "notecasts-ec2-role"

  assume_role_policy = jsondecode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "notecasts_instance_profile" {
  name = "notecasts-instance-profile"
  role = aws_iam_role.notecasts_role.name
}