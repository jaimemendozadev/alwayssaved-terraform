resource "aws_instance" "audio_extractor" {
  ami                         = var.aws_ami_id        # Replace with your preferred AMI
  instance_type               = var.aws_instance_type # Change based on service needs
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.notecasts_sg.id]
  associate_public_ip_address = true # ✅ Ensure a public IP is assigned
  iam_instance_profile        = aws_iam_instance_profile.notecasts_instance_profile.name
  key_name                    = aws_key_pair.notecasts_key.key_name # ✅ Assign the key to the instance

  tags = {
    Name = "notecasts-audio-extractor"
  }
}

resource "aws_key_pair" "notecasts_key" {
  key_name   = "notecasts-key"
  public_key = file("~/.ssh/jm-aws-key-pair-num2-03162025.pub")
}