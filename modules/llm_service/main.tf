resource "aws_instance" "llm_service" {
  ami                         = var.llm_service_ami_id
  instance_type               = var.llm_service_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = var.llm_service_vpc_security_group_ids
  associate_public_ip_address = true
  iam_instance_profile        = var.llm_service_iam_instance_profile
  key_name                    = var.aws_pub_key_name

  user_data = templatefile("${path.root}/scripts/llm_service_setup.sh", {
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