output "app_runner_service_url" {
  value     = aws_apprunner_service.sample_python_flask_app.service_url
  sensitive = true
}
