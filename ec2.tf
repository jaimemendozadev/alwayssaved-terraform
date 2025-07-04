resource "aws_instance" "audio_extractor" {
  ami                         = var.ubuntu_ami_id
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.always_saved_sg.id]
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
  security_groups             = [aws_security_group.always_saved_sg.id]
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
  ami                         = var.ubuntu_ami_id
  instance_type               = var.llm_service_instance_type # suggest t3.large
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.always_saved_sg.id]
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



