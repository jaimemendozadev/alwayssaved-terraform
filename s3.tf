# Reference the manually created S3 bucket (do NOT create it)
data "aws_s3_bucket" "alb_logs" {
  bucket = "alwayssaved-alb-logs"
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = data.aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSALBLogsPolicy1",
        Effect = "Allow",
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${data.aws_s3_bucket.alb_logs.arn}/alb/AWSLogs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSALBLogsPolicy2",
        Effect = "Allow",
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = data.aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}
