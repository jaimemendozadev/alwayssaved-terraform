#!/bin/bash
set -e

exec > >(tee /var/log/notecasts_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==== Updating System & Installing Base Dependencies ===="
sudo apt-get update -y
sudo apt-get install -y unzip systemd docker.io curl

echo "==== Installing AWS CLI via Official Installer ===="
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"

unzip -q awscliv2.zip
sudo ./aws/install
sudo ln -s /usr/local/bin/aws /usr/bin/aws || true

echo "==== Verifying AWS CLI ===="
aws --version

echo "==== Starting Docker ===="
sudo systemctl daemon-reexec
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

echo "==== Waiting for Docker Daemon to Settle ===="
sleep 10

echo "==== Authenticating Docker with AWS ECR ===="
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${ECR_URL}

echo "==== Pulling and Running Notecasts Extractor Container ===="
sudo docker pull ${ECR_URL}
sudo docker run -d --name notecasts-extractor ${ECR_URL}

echo "==== Deployment Complete ===="
