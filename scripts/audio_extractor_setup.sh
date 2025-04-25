#!/bin/bash
set -e

echo "==== Log everything to a file and to the EC2 console ===="
exec > >(tee /var/log/notecasts_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==== Updating System & Installing Base Dependencies ===="
sudo apt-get update -y
sudo apt-get install -y unzip systemd curl gnupg lsb-release

echo "==== Installing AWS CLI via Official Installer ===="
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip -q awscliv2.zip
sudo ./aws/install
sudo ln -s /usr/local/bin/aws /usr/bin/aws || true

echo "==== Verifying AWS CLI ===="
aws --version

echo "==== Installing Docker ===="
curl -fsSL https://get.docker.com | sh
sudo systemctl daemon-reexec
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

echo "==== Installing NVIDIA Container Toolkit ===="
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker


echo "==== Waiting for Docker Daemon to Settle ===="
sleep 10

echo "==== Authenticating Docker with AWS ECR ===="
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${ECR_URL}

echo "==== Pulling and Running Notecasts Extractor Container (with GPU) ===="
sudo docker pull ${ECR_URL}
sudo docker run --gpus all -d --name notecasts-extractor ${ECR_URL}

echo "==== Installing CloudWatch Agent ===="
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb

echo "==== Creating CloudWatch Agent Config ===="
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "/notecasts/transcriber",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 14
          }
        ]
      }
    }
  }
}
EOF

echo "==== Starting CloudWatch Agent ===="
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "==== Deployment Complete ===="