output "eb_env_url" {
  value     = aws_elastic_beanstalk_environment.sample_python_flask_app_env.endpoint_url
  sensitive = true
}
