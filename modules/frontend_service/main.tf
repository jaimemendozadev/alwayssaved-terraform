resource "aws_instance" "frontend_service" {
  ami                         = var.frontend_ami_id
  instance_type               = var.frontend_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = var.frontend_vpc_security_group_ids
  associate_public_ip_address = true
  iam_instance_profile        = var.frontend_instance_profile_name
  key_name                    = var.aws_pub_key_name

  user_data = templatefile("${path.root}/scripts/nextjs_frontend_setup.sh", {
    ECR_URL = var.aws_ecr_frontend_service_url
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "always-saved-frontend-service"
  }
}