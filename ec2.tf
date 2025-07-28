resource "aws_instance" "audio_extractor" {
  ami                         = var.ubuntu_ami_id
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.always_saved_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.always_saved_instance_profile.name
  key_name                    = var.aws_pub_key_name

  user_data = templatefile("${path.module}/scripts/audio_extractor_setup.sh", {
    ECR_URL = var.aws_ecr_extractor_service_url
  })

  root_block_device {
    volume_size = 100 # 🔥 Increase to 100 GB for plenty of breathing room
    volume_type = "gp3"
  }

  tags = {
    Name = "always-saved-audio-extractor"
  }
}

# TODO: Embedding ec2 Instance will need its own security group
resource "aws_instance" "embedding_service" {
  ami                         = var.embedding_ami_id
  instance_type               = var.embedding_instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.always_saved_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.always_saved_embedding_instance_profile.name
  key_name                    = var.aws_pub_key_name

  user_data = templatefile("${path.module}/scripts/embedding_service_setup.sh", {
    ECR_URL = var.aws_ecr_embedding_service_url
  })

  root_block_device {
    volume_size = 100 # 🔥 Increase to 100 GB for plenty of breathing room
    volume_type = "gp3"
  }

  tags = {
    Name = "always-saved-embedding-service"
  }
}


resource "aws_instance" "llm_service" {
  ami                         = var.llm_service_ami_id
  instance_type               = var.llm_service_instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.always_saved_sg.id, aws_security_group.internal_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.always_saved_llm_instance_profile.name
  key_name                    = var.aws_pub_key_name

  user_data = templatefile("${path.module}/scripts/llm_service_setup.sh", {
    ECR_URL = var.aws_ecr_llm_service_url
  })

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "always-saved-llm-service"
  }
}


resource "aws_instance" "frontend_service" {
  ami                         = var.frontend_ami_id
  instance_type               = var.frontend_instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.always_saved_sg.id, aws_security_group.internal_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.always_saved_frontend_instance_profile.name
  key_name                    = var.aws_pub_key_name

  user_data = templatefile("${path.module}/scripts/nextjs_frontend_setup.sh", {
    ECR_URL = var.aws_ecr_frontend_service_url
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "always-saved-frontend-service"
  }

  # ✅ Force Terraform to wait until the LLM EC2 is created
  depends_on = [aws_instance.llm_service]
}


# ----------------------
# 2. ALB and Target Group
# ----------------------
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





resource "aws_lb_target_group" "frontend" {
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
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.frontend_service.id
  port             = 80
}


resource "aws_lb_target_group" "llm" {
  name     = "llm-tg"
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
    Name = "llm-tg"
  }
}

resource "aws_lb_target_group_attachment" "llm_attachment" {
  target_group_arn = aws_lb_target_group.llm.arn
  target_id        = aws_instance.llm_service.id
  port             = 8000
}


# ----------------------
# 3. ALB Listeners (Redirect + HTTPS)
# ----------------------
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
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}


resource "aws_lb_listener_rule" "llm_path_proxy" {
  listener_arn = aws_lb_listener.https.arn
  priority = 10
  action  {
    type = "forward"
    target_group_arn = aws_lb_target_group.llm.arn
  }

  condition {
    path_pattern {
      values = ["/api/llm/*"]
    }
  }

}

