data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "jellyfin_cloudwatch_write_policy" {
  name        = "CloudWatchJellyfinLogsWriteAccess"
  description = "Allows sending logs to the Jellyfin CloudWatch Logs group"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "${aws_cloudwatch_log_group.jellyfin.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role" "jellyfin_role" {
  name = "jellyfin-role"
  assume_role_policy = jsonencode({
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
resource "aws_iam_role_policy_attachment" "jellyfin_cloudwatch_write_policy_attachment" {
  role       = aws_iam_role.jellyfin_role.name
  policy_arn = aws_iam_policy.jellyfin_cloudwatch_write_policy.arn
}

# This acts as a container for the IAM role. These usually map 1 to 1 to a role.
resource "aws_iam_instance_profile" "jellyfin_instance_profile" {
  name = "jellyfin-instance-profile"
  role = aws_iam_role.jellyfin_role.name
}

resource "aws_cloudwatch_log_group" "jellyfin" {
  name              = "/ec2/jellyfin"
  retention_in_days = 7
}
