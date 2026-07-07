
# ALB security group
resource "aws_security_group" "alb_sg" {
  name   = "${local.name_prefix}-alb-sg"
  vpc_id = aws_vpc.vpc01.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-alb-sg" })
}

# Target group for the private ASG instances
resource "aws_lb_target_group" "app_tg" {
  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc01.id

  health_check {
    path                = "/index.html"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-tg" })
}

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]

  tags = merge(var.tags, { Name = "${local.name_prefix}-alb" })
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
