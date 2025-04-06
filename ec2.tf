resource "aws_instance" "audio_extractor" {
  ami                         = var.ubuntu_ami_id # Ubuntu AMI (Replace in `variables.tf`)
  instance_type               = "t3.large"        # Equivalent to t2.large
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.notecasts_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.notecasts_instance_profile.name
  key_name                    = var.aws_pub_key_name

  user_data = <<EOF
#!/bin/bash
set -e

exec > >(tee /var/log/notecasts_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==== Updating System & Installing Dependencies ===="
sudo apt-get update -y
sudo apt-get install -y unzip systemd docker.io awscli

echo "==== Starting Docker ===="
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

echo "==== Authenticating Docker with AWS ECR ===="
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${var.aws_ecr_extractor_service_url}

echo "==== Pulling & Running Notecasts Extractor Container ===="
sudo docker pull ${var.aws_ecr_extractor_service_url}
sudo docker run -d --name notecasts-extractor -v /home/ubuntu/notecasts:/app ${var.aws_ecr_extractor_service_url}

echo "Deployment complete!"
EOF

  tags = {
    Name = "notecasts-audio-extractor"
  }
}





