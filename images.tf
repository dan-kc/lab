# Define s3 bucket for images
resource "aws_s3_bucket" "images_s3_bucket" {
  bucket = "machine-images-7xew9zev3eyueewy"
}

## VM import service role
resource "aws_iam_role" "vmimport_role" {
  name = "vmimport" # Must be exactly 'vmimport'

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vmie.amazonaws.com" # Specific service principal for VM Import/Export
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  description = "Service role for VM Import/Export operations."
}

resource "aws_iam_policy" "vmimport_policy" {
  name        = "vmimport-service-policy"
  description = "Policy for the vmimport service role to allow S3 and EC2 actions."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.images_s3_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.images_s3_bucket.bucket}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:ModifySnapshotAttribute",
          "ec2:CopySnapshot",
          "ec2:RegisterImage",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots",
          "ec2:DeleteSnapshot"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vmimport_policy_attachment" {
  role       = aws_iam_role.vmimport_role.name
  policy_arn = aws_iam_policy.vmimport_policy.arn
}
