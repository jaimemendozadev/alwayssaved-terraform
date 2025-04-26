resource "aws_instance" "audio_extractor" {
  ami                         = var.ubuntu_ami_id # Ubuntu AMI (Replace in `variables.tf`)
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.notecasts_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.notecasts_instance_profile.name
  key_name                    = var.aws_pub_key_name

  user_data = templatefile("${path.module}/scripts/audio_extractor_setup.sh", {
    ECR_URL = var.aws_ecr_extractor_service_url
  })

  root_block_device {
    volume_size = 64 # in GB
    volume_type = "gp3"
  }


  tags = {
    Name = "notecasts-audio-extractor"
  }
}





