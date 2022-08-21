terraform {
  cloud {
    organization = "misterjunio"
    workspaces {
      name = "sample-python-flask-app-elastic-beanstalk-python"
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

resource "aws_elastic_beanstalk_application" "sample_python_flask_app" {
  name = "sample-python-flask-app-python-platform"
}

resource "aws_iam_role" "eb_ec2_instance_role" {
  name = "ElasticBeanstalkEC2Role"
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
}

resource "aws_iam_role_policy_attachment" "eb_ec2_web_tier" {
  role       = aws_iam_role.eb_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_ec2_instance_profile" {
  name = "aws-elasticbeanstalk-ec2-role"
  role = aws_iam_role.eb_ec2_instance_role.name
}

resource "aws_elastic_beanstalk_environment" "sample_python_flask_app_env" {
  name                = var.eb_env_name
  application         = aws_elastic_beanstalk_application.sample_python_flask_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.3.16 running Python 3.8"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_instance_profile.name
  }
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "sample-python-flask-app-eb-bucket"
}

resource "aws_s3_object" "app_package" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "eb/${var.eb_app_version}.zip"
  source = "${var.eb_app_version}.zip"
}

resource "aws_elastic_beanstalk_application_version" "sample_python_flask_app_version" {
  name        = "sample-python-flask-app-python-${var.eb_app_version}"
  application = aws_elastic_beanstalk_application.sample_python_flask_app.name
  description = "Application version created by Terraform"
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.app_package.id
}
