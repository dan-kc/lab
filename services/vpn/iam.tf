data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "vpn_cloudwatch_write_policy" {
  name        = "CloudWatchVPNLogsWriteAccess"
  description = "Allows sending logs to the VPN CloudWatch Logs group"
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
        Resource = "${aws_cloudwatch_log_group.vpn.arn}:*"
      }
    ]
  })
}

data "aws_secretsmanager_secret" "wireguard_private_key_metadata" {
  name = "/vpn/wg-private-key"
}

resource "aws_iam_policy" "vpn_secrets_manager_read_policy" {
  name        = "VpnSecretsManagerReadAccess"
  description = "Allows retrieval of vpn secrets from Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SecretsManagerAccess",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
        ],
        Resource = data.aws_secretsmanager_secret.wireguard_private_key_metadata.arn 
      }
    ]
  })
}

resource "aws_iam_role" "vpn_role" {
  name = "vpn-role"
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

resource "aws_iam_role_policy_attachment" "vpn_secrets_manager_policy_attachment" {
  role       = aws_iam_role.vpn_role.name
  policy_arn = aws_iam_policy.vpn_secrets_manager_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "vpn_cloudwatch_write_policy_attachment" {
  role       = aws_iam_role.vpn_role.name
  policy_arn = aws_iam_policy.vpn_cloudwatch_write_policy.arn
}

# This acts as a container for the IAM role. These usually map 1 to 1 to a role.
resource "aws_iam_instance_profile" "vpn_instance_profile" {
  name = "vpn-instance-profile"
  role = aws_iam_role.vpn_role.name
}

resource "aws_cloudwatch_log_group" "vpn" {
  name              = "/ec2/vpn"
  retention_in_days = 7
}

