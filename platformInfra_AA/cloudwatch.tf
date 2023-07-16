# Create Log group for each Microservice
resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name = "${var.service.name}-LogGroup"
  retention_in_days = 7
}
