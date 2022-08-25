terraform {
  cloud {
    organization = "misterjunio"
    workspaces {
      name = "sample-python-flask-app-ecs-fargate"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.27"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "sample-python-flask-app-ecs-fargate-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "sample-python-flask-app-ecs-fargate-task-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

resource "aws_ecs_task_definition" "app_task_definition" {
  family                   = "sample-python-flask-app-ecs-fargate-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = file("./task_definition.json")
}

resource "aws_default_vpc" "app_vpc" {}

data "aws_subnets" "app_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.app_vpc.id]
  }
}

resource "aws_security_group" "app_security_group" {
  name   = "Sample Python Flask App ECS Fargate SG"
  vpc_id = aws_default_vpc.app_vpc.id

  ingress {
    from_port   = 5000
    to_port     = 5000
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

resource "aws_ecs_service" "app_service" {
  name                  = "sample-python-flask-app-ecs-fargate-service"
  cluster               = aws_ecs_cluster.app_cluster.arn
  task_definition       = aws_ecs_task_definition.app_task_definition.arn
  desired_count         = 1
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  network_configuration {
    subnets          = data.aws_subnets.app_subnets.ids
    security_groups  = [aws_security_group.app_security_group.id]
    assign_public_ip = true
  }
}
