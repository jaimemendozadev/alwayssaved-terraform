resource "aws_instance" "audio_extractor" {
  ami                         = var.aws_ami_id        # Replace with your preferred AMI
  instance_type               = var.aws_instance_type # Change based on service needs
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.notecasts_sg.id]
  associate_public_ip_address = true # ✅ Ensure a public IP is assigned. Do we still need this? 🤔
  iam_instance_profile        = aws_iam_instance_profile.notecasts_instance_profile.name
  key_name                    = aws_key_pair.notecasts_key.key_name # ✅ Assign the key to the instance
  user_data                   = <<EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install ruby -y
    sudo yum install wget -y
    cd /home/ec2-user
    wget https://aws-codedeploy-${var.aws_region}.s3.amazonaws.com/latest/install
    chmod +x ./install
    sudo ./install auto
    sudo systemctl enable codedeploy-agent
    sudo systemctl start codedeploy-agent
    EOF

  tags = {
    Name = "notecasts-audio-extractor"
  }
}

resource "aws_key_pair" "notecasts_key" {
  key_name   = "notecasts-key"
  public_key = var.aws_public_key
}