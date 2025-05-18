# Create ECR repository
resource "aws_ecr_repository" "mcpo_proxy" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Optional: Force delete the repository even if it contains images
  force_delete = true
}

# # Add lifecycle policy to cleanup old images (optional)
# resource "aws_ecr_lifecycle_policy" "mcpo_proxy_lifecycle" {
#   repository = aws_ecr_repository.mcpo_proxy.name
#
#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1,
#         description  = "Keep last 10 images",
#         selection = {
#           tagStatus     = "any",
#           countType     = "imageCountMoreThan",
#           countNumber   = 10
#         },
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }

# # Get ECR login token
# data "aws_ecr_authorization_token" "token" {}

# Build and push Docker image
resource "null_resource" "docker_build_and_push" {
  triggers = {
    dockerfile_hash = filemd5("${var.dockerfile_path}/Dockerfile")
    config_hash     = filemd5("${var.dockerfile_path}/config.json")
  }

  provisioner "local-exec" {
    command = <<EOT
      # Login to ECR
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

      # Build the Docker image
      docker build  -t ${aws_ecr_repository.mcpo_proxy.repository_url}:${var.image_tag} ${var.dockerfile_path} --platform=linux/amd64

      # Push the image to ECR
      docker push ${aws_ecr_repository.mcpo_proxy.repository_url}:${var.image_tag}
    EOT
  }

  depends_on = [
    aws_ecr_repository.mcpo_proxy
  ]
}