# helped myself with:
# - ChatGPT
# - AWS documentation https://docs.aws.amazon.com/
# - Terraform aws provider documentation https://registry.terraform.io/providers/hashicorp/aws/latest/docs
#    - TODO: https://repost.aws/knowledge-center/ecs-fargate-static-elastic-ip-address
# - good people with public repositories:
#   - crystallized useless!
# - https://marc.it/how-to-create-an-ecs-cluster-using-terraform/
# - https://containersonaws.com/pattern/nginx-reverse-proxy-sidecar-ecs-fargate-task

provider "aws" {
  region = var.aws_region # Specify the desired AWS region
}

# --------------------------------------------------------------------------------------
# AQvis ECR repositories

resource "aws_ecr_repository" "aqvis_backend_repository" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  name                 = "aqvis-backend"
  image_tag_mutability = "MUTABLE" # or "IMMUTABLE"
}

output "aqvis_backend_repository_url" {
  value = aws_ecr_repository.aqvis_backend_repository.repository_url
}

resource "aws_ecr_repository" "aqvis_frontend_repository" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  name                 = "aqvis-frontend"
  image_tag_mutability = "MUTABLE" # or "IMMUTABLE"
}

output "aqvis_frontend_repository_url" {
  value = aws_ecr_repository.aqvis_frontend_repository.repository_url
}

resource "aws_ecr_repository" "aqvis_nginx_repository" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  name                 = "aqvis-nginx"
  image_tag_mutability = "MUTABLE" # or "IMMUTABLE"
}

output "aqvis_nginx_repository_url" {
  value = aws_ecr_repository.aqvis_nginx_repository.repository_url
}

# AQvis ECR repositories
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------
# AQvis ECS

resource "aws_ecs_cluster" "aqvis_ecs_cluster" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  name = "aqvis-ecs-cluster"
}

resource "aws_iam_role" "aqvis_ecs_task_execution_role" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  name = "aqvisEcsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.aqvis_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "aqvis_ecs_task_definition" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  family                   = "aqvis-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn = aws_iam_role.aqvis_ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name = "aqvis-nginx"
      image = "${aws_ecr_repository.aqvis_nginx_repository.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80,
          hostPort = 80,
        }
      ]
      environment = [
        {
          name  = "FRONTEND_SERVICE_HOST"
          value = "localhost"
        },
        {
          name  = "FRONTEND_SERVICE_PORT"
          value = "3000"
        },
        {
          name  = "BACKEND_SERVICE_HOST"
          value = "localhost"
        },
        {
          name  = "BACKEND_SERVICE_PORT"
          value = "8000"
        }
      ]
    },
    {
      name = "aqvis-frontend"
      image = "${aws_ecr_repository.aqvis_frontend_repository.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
    },
    {
      name      = "aqvis-backend"
      image     = "${aws_ecr_repository.aqvis_backend_repository.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
#          protocol      = "tcp"
#          appProtocol   = "http"
        }
      ]
      environment = [
        {
          name  = "ACCESS_TOKEN_EXPIRE_MINUTES"
          value = "360"
        },
        {
          name  = "AWS_ACCESS_KEY_ID"
          value = var.aws_secret_key_id
        },
        {
          name  = "AWS_SECRET_ACCESS_KEY"
          value = var.aws_secret_access_key
        },
        {
          name  = "MONGODB_CONNECTION_URI_TEST"
          value = var.mongodb_connection_uri_test
        },
        {
          name  = "ALGORITHM"
          value = "HS256"
        },
        {
          name  = "DB_NAME_TEST"
          value = "aqvis_test"
        },
        {
          name  = "SECRET_KEY"
          value = var.secret_key
        },
        {
          name  = "DB_NAME"
          value = "aqvis"
        },
        {
          name  = "AWS_REGION_NAME"
          value = var.aws_region
        },
        {
          name  = "MONGODB_CONNECTION_URI"
          value = var.mongodb_connection_uri
        }
      ]
    }
  ])
}

# ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---
# AQvis ECS - network
resource "aws_vpc" "aqvis_vpc" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "aqvis_subnet" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  vpc_id                  = aws_vpc.aqvis_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "aqvis_internet_gateway" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  vpc_id = aws_vpc.aqvis_vpc.id
}

resource "aws_route_table" "aqvis_route_table" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  vpc_id = aws_vpc.aqvis_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aqvis_internet_gateway.id
  }
}

resource "aws_route_table_association" "aqvis_route_table_association" {
  subnet_id      = aws_subnet.aqvis_subnet.id
  route_table_id = aws_route_table.aqvis_route_table.id
}

resource "aws_security_group" "aqvis_security_group" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  vpc_id = aws_vpc.aqvis_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AQvis ECS - network
# ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

resource "aws_ecs_service" "aqvis_ecs_service" {
  tags = {
    app            = "aqvis"
    provisioned_by = "terraform"
  }
  name            = "aqvis-ecs-service"
  cluster         = aws_ecs_cluster.aqvis_ecs_cluster.id
  task_definition = aws_ecs_task_definition.aqvis_ecs_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.aqvis_subnet.id]
    security_groups  = [aws_security_group.aqvis_security_group.id]
    assign_public_ip = true
  }
}

#output "ecs_cluster_name" {
#  value = aws_ecs_cluster.aqvis_ecs_cluster.name
#}
#
#output "ecs_service_name" {
#  value = aws_ecs_service.aqvis_ecs_service.name
#}


# AQvis ECS
# --------------------------------------------------------------------------------------
