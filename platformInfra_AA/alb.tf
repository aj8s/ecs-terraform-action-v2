resource "aws_lb_target_group" "target_group" {
  name            = var.service.name
  port            = var.service.container_port
  protocol        = "HTTP"
  vpc_id          = data.terraform_remote_state.baseinfra.outputs.vpc_id
  target_type     = "ip" 

  depends_on = [aws_lb_listener_rule.listener_rule]

  health_check {
    path                = var.service.health_check_path
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = var.service.name
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = data.terraform_remote_state.baseinfra.outputs.ecs_alb_listener_arn
  priority     = 100 + var.service.container_port

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    path_pattern {
      values = [ "/${var.service.path_pattern}/*" ]
    }
  }
}

resource "aws_lb_target_group_attachment" "attachment" {
  count             = length(var.service.target_instances)
  target_group_arn  = aws_lb_target_group.target_group.arn
  target_id         = var.service.target_instances[count.index]
}