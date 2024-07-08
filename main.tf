provider "aws" {
  region = "eu-central-1"  # Specify the desired AWS region
}

# ######################################################################
# AQvis backend ECR

resource "aws_ecr_repository" "aqvis_backend_repository" {
  name                 = "aqvis-backend"
  image_tag_mutability = "MUTABLE"  # or "IMMUTABLE"
}

output "aqvis_backend_repository_url" {
  value = aws_ecr_repository.aqvis_backend_repository.repository_url
}

# AQvis backend ECR
# ######################################################################

# ######################################################################
# AQvis frontend ECR

resource "aws_ecr_repository" "aqvis_frontend_repository" {
  name                 = "aqvis-frontend"
  image_tag_mutability = "MUTABLE"  # or "IMMUTABLE"
}

output "aqvis_frontend_repository_url" {
  value = aws_ecr_repository.aqvis_frontend_repository.repository_url
}

# AQvis frontend ECR
# ######################################################################
