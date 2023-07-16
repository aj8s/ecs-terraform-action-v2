resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.service.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.service.per_container_cpu
  memory                   = var.service.per_container_memory
  task_role_arn            = data.terraform_remote_state.baseinfra.outputs.ecs_cluster_role_arn
  execution_role_arn       = data.terraform_remote_state.baseinfra.outputs.ecs_task_execution_role_arn
  container_definitions = jsonencode([
    {
      "name" : "${var.service.name}",
      "image" : format("%s:%s", data.aws_ecr_repository.service.repository_url, var.image_tag),
      "essential" : true,
      "environment" : [
        {
          "name" : "SPRING_PROFILES_ACTIVE",
          "value" : "${var.service.spring_profiles}"
        },
        {
          "name" : "SPRING_DATASOURCE_USERNAME",
          "value" : local.db_creds["username"]
        },
        {
          "name" : "SPRING_PORT",
          "value" : format("%v", var.service.container_port)
        }
      ],
      "portMappings" : [
        {
          "containerPort" : var.service.container_port,
          "hostPort" : var.service.container_port,
          "protocol" : "tcp"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "${var.service.name}-LogGroup",
          "awslogs-region" : var.aws_region,
          "awslogs-stream-prefix" : "${var.service.name}-LogStream"
        }
      },
    }
  ])
}


# Create ECS Service for each microservice
resource "aws_ecs_service" "ecs_service" {

  name            = var.service.name
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.service.desired_task_count
  cluster         = data.terraform_remote_state.baseinfra.outputs.ecs_cluster_id
  launch_type     = var.launch_type

  network_configuration {
    subnets          = flatten([data.terraform_remote_state.baseinfra.outputs.public_subnets])
    security_groups  = [data.terraform_remote_state.baseinfra.outputs.ecs-sg-id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = var.service.name
    container_port   = var.service.container_port
  }
}

