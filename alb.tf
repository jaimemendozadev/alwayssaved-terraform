############################################
# ALB and Target Group
############################################
resource "aws_lb" "alwayssaved_alb" {
  name               = "alwayssaved-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_2.id
  ]

  enable_deletion_protection = false

  access_logs {
    bucket  = data.aws_s3_bucket.alb_logs.bucket
    enabled = true
    prefix  = "alb"
  }

  tags = {
    Name = "alwayssaved-alb"
  }
}




resource "aws_lb_target_group" "frontend_target_group" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.always_saved_vpc.id

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "frontend-tg"
  }
}

resource "aws_lb_target_group_attachment" "frontend_attachment" {
  target_group_arn = aws_lb_target_group.frontend_target_group.arn
  target_id        = aws_instance.frontend_app.id
  port             = 80
}



############################################
# ALB Listeners (Redirect + HTTPS)
############################################
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.alwayssaved_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alwayssaved_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.frontend_ssl_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }
}


############################################
# LLM ALB and Target Group
############################################

resource "aws_lb" "llm_alb" {
  name               = "alwayssaved-llm-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.llm_alb_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "alwayssaved-llm-alb"
  }
}

resource "aws_lb_target_group" "llm_external" {
  name     = "llm-external-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.always_saved_vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "llm-external-tg"
  }
}

resource "aws_lb_target_group_attachment" "llm_external_attachment" {
  target_group_arn = aws_lb_target_group.llm_external.arn
  target_id        = aws_instance.llm_service.id
  port             = 8000
}


############################################
# LLM ALB Listeners
############################################

resource "aws_lb_listener" "llm_https" {
  load_balancer_arn = aws_lb.llm_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.llm_ssl_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.llm_external.arn
  }
}
