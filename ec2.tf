resource "aws_instance" "audio_extractor" {
  ami             = "ami-0abcdef1234567890" # Replace with your preferred AMI
  instance_type   = "t3.micro" # Change based on service needs
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.notecasts_sg.id]
  iam_instance_profile = aws_iam_instance_profile.notecasts_instance_profile.name

  tags = {
    Name = "notecasts-audio-extractor"
  }
}
