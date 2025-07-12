resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name

  network_interfaces {
    associate_public_ip_address = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name}-instance"
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg-v2"
  max_size            = 2
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.this.arn]
  health_check_type   = "ELB"
  force_delete        = true

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }
}

resource "aws_lb" "this" {
  name                       = "${var.name}-alb-v2"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.subnet_ids
  enable_deletion_protection = false

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg-v2"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 60
    matcher             = "200-399"
    path                = "/health.html"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 30
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}