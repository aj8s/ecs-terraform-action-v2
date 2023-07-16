variable "aws_region" {
  description = "Default AWS region"
  default     = "us-east-1"
}

variable "environment" {
  default     = "stage"
}

variable "remote_state_bucket" {}
variable "remote_state_key" {}

# Common Application Variables

variable "ecs_task_definition_family" {
    default = "springboot-task-definition"
}

variable "launch_type" {
    default = "FARGATE"
}

variable "image_tag" {
    default = "latest"
}

# This map must be defined in the respective environment's tfvars file
variable "service" {
  type = object({
    name                  = string
    container_port        = number
    spring_profiles       = string
    per_container_cpu     = number
    per_container_memory  = number
    health_check_path     = string
    path_pattern          = string
    desired_task_count    = number
  })
  description = "The microservice object being deployed"
}
