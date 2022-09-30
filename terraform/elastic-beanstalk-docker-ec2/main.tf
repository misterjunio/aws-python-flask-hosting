terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_elastic_beanstalk_application" "sample_python_flask_app" {
  name = "sample-python-flask-app-docker-ec2-platform"
}

resource "aws_iam_role" "eb_ec2_instance_role" {
  name = "ElasticBeanstalkDockerECSPlatformEC2Role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_instance_profile" "eb_ec2_instance_profile" {
  name = "aws-elasticbeanstalk-docker-ec2-platform-ec2-role"
  role = aws_iam_role.eb_ec2_instance_role.name
}

resource "aws_elastic_beanstalk_environment" "sample_python_flask_app_env" {
  name                = var.eb_env_name
  application         = aws_elastic_beanstalk_application.sample_python_flask_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.18 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_instance_profile.name
  }
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "sample-python-flask-app-eb-docker-ec2-platform-bucket"
}

resource "aws_s3_object" "app_image_file" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "eb/Dockerrun.aws.json"
  source = "Dockerrun.aws.json"
}

resource "aws_elastic_beanstalk_application_version" "sample_python_flask_app_version" {
  name        = "sample-python-flask-app-docker-ec2-${var.eb_app_version}"
  application = aws_elastic_beanstalk_application.sample_python_flask_app.name
  description = "Application version created by Terraform"
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.app_image_file.id
}
