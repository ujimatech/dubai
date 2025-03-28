# Create the S3 bucket
resource "aws_s3_bucket" "openwebui_storage" {
  bucket = "${var.project_name}-openwebui-storage"

  tags = {
    Name        = "OpenWebUI Storage"
    Environment = "Production"
    Service     = "OpenWebUI"
  }
}

# Configure default encryption for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "openwebui_storage" {
  bucket = aws_s3_bucket.openwebui_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create IAM User
resource "aws_iam_user" "openwebui_user" {
  name = "${var.project_name}-openwebui-s3-user"
  path = "/service/"

  tags = {
    Description = "${var.project_name} Service user for OpenWebUI storage access"
    Service     = "OpenWebUI"
  }
}

# Create an IAM policy for bucket access
resource "aws_iam_policy" "openwebui_bucket_policy" {
  name        = "${var.project_name}-openwebui-s3-bucket-policy"
  description = "Policy granting access to the openwebui-storage bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.openwebui_storage.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = "${aws_s3_bucket.openwebui_storage.arn}/*"
      }
    ]
  })
}

# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "attach_bucket_policy" {
  user       = aws_iam_user.openwebui_user.name
  policy_arn = aws_iam_policy.openwebui_bucket_policy.arn
}

