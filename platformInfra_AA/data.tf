data "aws_secretsmanager_secret" "secrets" {
  name = "psqladmin-${var.environment}"
}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}
 
data "aws_ecr_repository" "service" {
  name = var.service.name
}

output "ecr_repository_url" {
  value = data.aws_ecr_repository.service.repository_url
}