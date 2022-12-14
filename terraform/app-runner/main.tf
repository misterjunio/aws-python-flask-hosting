terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_iam_role" "app_runner_ecr_access" {
  name = "AppRunnerECRAccessRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "build.apprunner.amazonaws.com",
            "tasks.apprunner.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"]
}

resource "aws_apprunner_service" "sample_python_flask_app" {
  service_name = "sample-python-flask-app"

  source_configuration {
    image_repository {
      image_configuration {
        port = "5000"
      }
      image_identifier      = var.ecr_repo_arn
      image_repository_type = "ECR"
    }
    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_ecr_access.arn
    }
    auto_deployments_enabled = false
  }
}
