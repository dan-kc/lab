# Get region and account_id
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "forgejo_secrets_manager_read_policy" {
  name        = "ForgejoSecretsManagerReadAccess"
  description = "Allows retrieval of forgejo secrets from Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SecretsManagerAccess",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${aws_secretsmanager_secret.forgejo_db_credentials.name}-*"
      }
    ]
  })
}

resource "aws_iam_policy" "my_app_efs_access_policy" {
  name        = "MyApplicationEFSAccess"
  description = "Allows ECS task to mount and access a specific EFS file system"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EFSAccess",
        Effect = "Allow",
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRead",
        ],
        Resource = "arn:aws:elasticfilesystem:<REGION>:<ACCOUNT_ID>:file-system/<YOUR_EFS_FILE_SYSTEM_ID>"
      }
    ]
  })
}
